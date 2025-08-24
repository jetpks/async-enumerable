# frozen_string_literal: true

require "forwardable"
require "async/enumerable/config"
require "async/enumerable/fiber_limiter"
require "async/enumerable/methods"

module Async
  # Wrapper providing async enumerable methods for parallel execution.
  # See docs/reference/enumerator.md for detailed documentation.
  class Enumerator
    include Async::Enumerable
    def_enumerator :@enumerable

    # Delegate methods that are inherently sequential back to the wrapped enumerable
    extend Forwardable
    def_delegators :@enumerable, :first, :take, :take_while, :lazy, :size, :length

    # Creates async wrapper for enumerable.
    # @param enumerable [Enumerable] Object to wrap
    # @param config [Config, nil] Configuration object
    # @param kwargs [Hash] Configuration options (max_fibers, etc.)
    def initialize(enumerable = [], config = nil, **kwargs)
      @enumerable = enumerable

      # Handle the common case of Enumerator.new(enumerable, max_fibers: n)
      if config.is_a?(Hash)
        kwargs = config
        config = nil
      end

      # Start with base config (module config or default)
      base = config || Async::Enumerable.config

      # Apply kwargs if any
      @async_enumerable_config = kwargs.empty? ? base : base.with(**kwargs)
    end

    # Executes block for each element in parallel.
    # @yield [item] Block to run for each element
    # @return [self, Enumerator] Self for chaining or Enumerator without block
    def each(&block)
      return enum_for(__method__) unless block_given?

      with_bounded_concurrency do |barrier|
        @enumerable.each do |item|
          barrier.async do
            block.call(item)
          end
        end
      end

      # Return self to allow chaining, like standard each
      self
    end

    # Compares with another enumerable.
    # @param other [Object] Object to compare
    # @return [Integer, nil] Comparison result
    def <=>(other)
      return nil unless other.respond_to?(:to_a)
      to_a <=> other.to_a
    end

    # Checks equality with another enumerable.
    # @param other [Object] Object to compare
    # @return [Boolean] True if equal
    def ==(other)
      return false unless other.respond_to?(:to_a)
      to_a == other.to_a
    end
    alias_method :eql?, :==
  end
end
