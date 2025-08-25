# frozen_string_literal: true

require "async"
require "async/barrier"
require "async/semaphore"

require "concurrent/array"
require "concurrent/atomic/atomic_boolean"
require "concurrent/atomic/atomic_fixnum"
require "concurrent/atomic/atomic_reference"

require "forwardable"

module Async
  module Enumerable
  end
end

require "async/enumerable/configurable"
require "async/enumerable/concurrency_bounder"
require "async/enumerable/comparable"
require "async/enumerable/class_methods"
require "async/enumerable/methods"
require "async/enumerable/version"

module Async
  # Provides async parallel execution for Enumerable.
  # See docs/reference/enumerable.md for detailed documentation.
  module Enumerable
    @__async_enumerable_config_ref = Concurrent::AtomicReference.new(Configurable::Config.new)
    extend Configurable
    include Configurable

    class << self
      alias_method :config, :__async_enumerable_config
      alias_method :configure, :__async_enumerable_config

      def included(base)
        base.extend(Configurable)
        base.extend(ClassMethods)
        base.include(Comparable)
        base.include(Methods)
        base.include(AsyncMethod)
      end

      def config_ref
        @__async_enumerable_config_ref
      end
    end

    # Async method module - included last to override Enumerable's version.
    module AsyncMethod
      # Returns async enumerator (idempotent - returns self if already async).
      # @param kwargs [Hash] Configuration options (max_fibers, etc.)
      # @return [Async::Enumerator] Async wrapper
      def async(**kwargs)
        return self if kwargs.empty? && self.class.include?(Async::Enumerable)

        source = __async_enumerable_collection || self
        config = __async_enumerable_config
        Async::Enumerator.new(source, config, **kwargs)
      end
    end
  end
end

require "async/enumerator"
require "enumerable/async"
