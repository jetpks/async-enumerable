# frozen_string_literal: true

require "async"
require "async/barrier"
require "async/semaphore"

require "concurrent/array"
require "concurrent/atomic/atomic_boolean"
require "concurrent/atomic/atomic_fixnum"
require "concurrent/atomic/atomic_reference"

module Async
  module Enumerable
  end
end

require "async/enumerable/config"
require "async/enumerable/fiber_limiter"
require "async/enumerable/methods"
require "async/enumerable/version"

module Async
  # Provides async parallel execution for Enumerable.
  # See docs/reference/enumerable.md for detailed documentation.
  module Enumerable
    DEFAULT_MAX_FIBERS = 1024

    class << self
      attr_accessor :config

      # Gets default max fibers (defaults to 1024).
      # @return [Integer] Maximum fiber limit
      def max_fibers
        config&.max_fibers || DEFAULT_MAX_FIBERS
      end

      # Sets default max fibers.
      # @param value [Integer] Maximum fiber limit
      def max_fibers=(value)
        self.config = (config || Config.default).with(max_fibers: value)
      end
    end

    def self.included(base)
      base.include(::Enumerable)
      base.include(::Comparable)
      base.extend(ClassMethods)
      base.include(Methods)      # Include all method groups
      base.include(FiberLimiter) # Include fiber limiting functionality
      base.include(AsyncMethod)  # Include async method last to override Enumerable's

      # Initialize config instance variable for Async::Enumerator
      # (not for other classes that include this module)
      if base == ::Async::Enumerator
        base.class_eval do
          # This will be set in initialize, but we define it here for clarity
          @async_enumerable_config = nil
        end
      end
    end

    # Async method module - included last to override Enumerable's version.
    module AsyncMethod
      # Returns async enumerator (idempotent - returns self if already async).
      # @param max_fibers [Integer, nil] Concurrency limit
      # @return [Async::Enumerator] Async wrapper
      def async(max_fibers: nil)
        # If we're already an Async::Enumerator, just return self
        # This makes .async.async.async idempotent
        return self if is_a?(::Async::Enumerator)

        if self.class.respond_to?(:enumerable_source) && self.class.enumerable_source
          source_method = self.class.enumerable_source
          # Handle instance variables (e.g., :@enumerable)
          source = if source_method.is_a?(Symbol) && source_method.to_s.start_with?("@")
            instance_variable_get(source_method)
          else
            send(source_method)
          end
          # Create config if class has default_max_fibers
          if self.class.default_max_fibers
            config = Config.new(max_fibers: self.class.default_max_fibers)
            if max_fibers
              ::Async::Enumerator.new(source, config, max_fibers: max_fibers)
            else
              ::Async::Enumerator.new(source, config)
            end
          elsif max_fibers
            ::Async::Enumerator.new(source, nil, max_fibers: max_fibers)
          else
            ::Async::Enumerator.new(source)
          end
        else
          # If no source is defined, assume self is enumerable
          source = self
          if max_fibers
            ::Async::Enumerator.new(source, nil, max_fibers: max_fibers)
          else
            ::Async::Enumerator.new(source)
          end
        end
      end
    end

    module ClassMethods
      # Defines enumerable source for async operations.
      # @param method_name [Symbol] Method/ivar returning enumerable
      # @param max_fibers [Integer, nil] Default concurrency limit
      def def_enumerator(method_name, max_fibers: nil)
        @enumerable_source = method_name
        @default_max_fibers = max_fibers
      end

      attr_reader :enumerable_source, :default_max_fibers
    end
  end
end

require "async/enumerator"
require "enumerable/async"
