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
    class << self
      # Gets or creates the module-level config.
      # @param kwargs [Hash] Optional configuration updates
      # @return [Config] Module configuration
      def config(**kwargs)
        @config ||= Config.default
        @config = @config.with(**kwargs) unless kwargs.empty?
        @config
      end

      # Gets default max fibers (defaults to 1024).
      # @return [Integer] Maximum fiber limit
      def max_fibers
        config.max_fibers
      end

      # Sets default max fibers.
      # @param value [Integer] Maximum fiber limit
      def max_fibers=(value)
        config(max_fibers: value)
      end
    end

    def self.included(base)
      base.include(::Enumerable)
      base.include(::Comparable)
      base.extend(ClassMethods)
      base.include(Methods)      # Include all method groups
      base.include(FiberLimiter) # Include fiber limiting functionality
      base.include(AsyncMethod)  # Include async method last to override Enumerable's
      base.include(ConfigAccessor) # Include config accessor method
    end

    # Module providing config accessor method
    module ConfigAccessor
      def __async_enumerable_config
        @async_enumerable_config
      end
    end

    # Async method module - included last to override Enumerable's version.
    module AsyncMethod
      # Returns async enumerator (idempotent - returns self if already async).
      # @param kwargs [Hash] Configuration options (max_fibers, etc.)
      # @return [Async::Enumerator] Async wrapper
      def async(**kwargs)
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
          ::Async::Enumerator.new(source, **kwargs)
        else
          # If no source is defined, assume self is enumerable
          ::Async::Enumerator.new(self, **kwargs)
        end
      end
    end

    module ClassMethods
      # Defines enumerable source for async operations.
      # @param method_name [Symbol] Method/ivar returning enumerable
      # @param max_fibers [Integer, nil] Default concurrency limit (kept for compatibility)
      def def_enumerator(method_name, max_fibers: nil)
        @enumerable_source = method_name
        # max_fibers parameter kept for backward compatibility but not used
        # Users should pass max_fibers to .async() method instead
      end

      attr_reader :enumerable_source
    end
  end
end

require "async/enumerator"
require "enumerable/async"
