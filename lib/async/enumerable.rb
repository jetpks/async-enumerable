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
    # Initialize the config reference once when the module loads
    @config_ref = Concurrent::AtomicReference.new(Config.default)

    class << self
      # Gets or creates the module-level config.
      # @param kwargs [Hash] Optional configuration updates
      # @return [Config] Module configuration
      def config(**kwargs)
        # Get the current config
        current = @config_ref.get

        # If kwargs provided, create updated config and set it
        unless kwargs.empty?
          updated = current.with(**kwargs)
          @config_ref.set(updated)
          current = updated
        end

        current
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
    end

    # Instance method to get config with proper precedence
    def __async_enumerable_config
      @async_enumerable_config ||
        self.class.__async_enumerable_config ||
        Async::Enumerable.config
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
          # Pass the class config if no kwargs provided
          if kwargs.empty? && self.class.respond_to?(:__async_enumerable_config)
            ::Async::Enumerator.new(source, self.class.__async_enumerable_config)
          else
            ::Async::Enumerator.new(source, **kwargs)
          end
        elsif kwargs.empty? && self.class.respond_to?(:__async_enumerable_config)
          # If no source is defined, assume self is enumerable
          ::Async::Enumerator.new(self, self.class.__async_enumerable_config)
        else
          ::Async::Enumerator.new(self, **kwargs)
        end
      end
    end

    module ClassMethods
      # Defines enumerable source for async operations.
      # @param method_name [Symbol] Method/ivar returning enumerable
      # @param kwargs [Hash] Configuration options (max_fibers, etc.)
      def def_enumerator(method_name, **kwargs)
        @enumerable_source = method_name
        # Create class-level config if any options provided
        @class_config = Config.new(**kwargs) unless kwargs.empty?
      end

      # Class method to get config with proper precedence
      def __async_enumerable_config
        @class_config || Async::Enumerable.config
      end

      attr_reader :enumerable_source
    end
  end
end

require "async/enumerator"
require "enumerable/async"
