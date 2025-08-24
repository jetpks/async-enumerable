# frozen_string_literal: true

require "forwardable"
require "async/enumerable/fiber_limiter"
require "async/enumerable/methods"

module Async
  # Enumerator is a wrapper class that provides asynchronous
  # implementations of Enumerable methods for parallel execution.
  #
  # This class wraps any Enumerable object and provides async versions of
  # standard enumerable methods. It includes the standard Enumerable module
  # for compatibility, as well as specialized async implementations through
  # the EarlyTerminable module.
  #
  # The Enumerator maintains a reference to the original enumerable and
  # delegates method calls while providing concurrent execution capabilities
  # through the async runtime.
  #
  # @example Creating an Async::Enumerator
  #   async_enum = Async::Enumerator.new([1, 2, 3, 4, 5])
  #   async_enum.map { |n| n * 2 }  # Executes in parallel
  #
  # @example Using through Enumerable#async
  #   # The preferred way to create an Async::Enumerator
  #   result = [1, 2, 3].async.map { |n| slow_operation(n) }
  #
  # @example With custom fiber limit
  #   huge_dataset.async(max_fibers: 100).map { |n| process(n) }
  #
  # @see Enumerable::Methods
  class Enumerator
    include Async::Enumerable
    def_enumerator :@enumerable

    # Delegate methods that are inherently sequential back to the wrapped enumerable
    extend Forwardable
    def_delegators :@enumerable, :first, :take, :take_while, :lazy, :size, :length

    # Creates a new Async::Enumerator wrapping the given enumerable.
    #
    # @param enumerable [Enumerable] Any object that includes Enumerable
    #
    # @param max_fibers [Integer, nil] Maximum number of concurrent fibers,
    #   defaults to Async::Enumerable.max_fibers
    #
    # @example Default fiber limit
    #   async_array = Async::Enumerator.new([1, 2, 3])
    #
    # @example Custom fiber limit
    #   async_range = Async::Enumerator.new(1..100, max_fibers: 50)
    def initialize(enumerable, max_fibers: nil)
      @enumerable = enumerable
      @max_fibers = max_fibers
    end

    # Asynchronously iterates over each element in the enumerable, executing
    # the given block in parallel for each item.
    #
    # This method spawns async tasks for each item in the enumerable,
    # allowing them to execute concurrently. It uses an Async::Barrier to
    # coordinate the tasks and waits for all of them to complete before
    # returning.
    #
    # When called without a block, returns an Enumerator for compatibility
    # with the standard Enumerable interface.
    #
    # @yield [item] Gives each element to the block in parallel
    # @yieldparam item The current item from the enumerable
    #
    # @return [self, Enumerator] Returns self when block given (for chaining),
    #   or an Enumerator when no block given
    #
    # @example Basic async iteration
    #   [1, 2, 3].async.each do |n|
    #     puts "Processing #{n}"
    #     sleep(1)  # All three will complete in ~1 second total
    #   end
    #
    # @example With I/O operations
    #   urls.async.each do |url|
    #     response = HTTP.get(url)
    #     save_to_cache(url, response)
    #   end
    #   # All URLs are fetched and cached concurrently
    #
    # @example Chaining
    #   data.async
    #       .each { |item| log(item) }
    #       .map { |item| transform(item) }
    #
    # @note The execution order of the block is not guaranteed to match
    #   the order of items in the enumerable due to parallel execution
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

    # Compares this Async::Enumerator with another object.
    # Converts both to arrays for comparison.
    #
    # @param other [Object] The object to compare with
    # @return [Integer, nil] -1, 0, 1, or nil based on comparison
    #
    # @example Comparing with an array
    #   async_enum = [1, 2, 3].async
    #   async_enum <=> [1, 2, 3]  # => 0
    #   async_enum <=> [1, 2, 4]  # => -1
    def <=>(other)
      return nil unless other.respond_to?(:to_a)
      to_a <=> other.to_a
    end

    # Checks equality with another object.
    # Converts both to arrays for comparison.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean] true if equal, false otherwise
    #
    # @example Testing equality with an array
    #   result = [1, 2, 3].async.map { |x| x * 2 }
    #   result == [2, 4, 6]  # => true
    def ==(other)
      return false unless other.respond_to?(:to_a)
      to_a == other.to_a
    end
    alias_method :eql?, :==
  end
end
