# frozen_string_literal: true

module AsyncEnumerable
  # AsyncEnumerator is a wrapper class that provides asynchronous implementations
  # of Enumerable methods for parallel execution.
  #
  # This class wraps any Enumerable object and provides async versions of standard
  # enumerable methods. It includes the standard Enumerable module for compatibility,
  # as well as specialized async implementations through the Each and EarlyTerminable modules.
  #
  # The AsyncEnumerator maintains a reference to the original enumerable and delegates
  # method calls while providing concurrent execution capabilities through the async runtime.
  #
  # @example Creating an AsyncEnumerator
  #   async_enum = AsyncEnumerable::AsyncEnumerator.new([1, 2, 3, 4, 5])
  #   async_enum.map { |n| n * 2 }  # Executes in parallel
  #
  # @example Using through Enumerable#async
  #   # The preferred way to create an AsyncEnumerator
  #   result = [1, 2, 3].async.map { |n| slow_operation(n) }
  #
  # @see Each
  # @see EarlyTerminable
  class AsyncEnumerator
    # Includes standard Enumerable for compatibility and method delegation
    include Enumerable

    # Includes async implementation of #each method for parallel iteration
    include Each

    # Includes optimized async implementations of early-terminable methods
    # (all?, any?, none?, one?, include?, find, find_index, first, take, take_while)
    include EarlyTerminable

    # Creates a new AsyncEnumerator wrapping the given enumerable.
    #
    # @param enumerable [Enumerable] Any object that includes Enumerable
    #
    # @example
    #   async_array = AsyncEnumerable::AsyncEnumerator.new([1, 2, 3])
    #   async_range = AsyncEnumerable::AsyncEnumerator.new(1..100)
    #   async_hash = AsyncEnumerable::AsyncEnumerator.new({a: 1, b: 2})
    def initialize(enumerable)
      @enumerable = enumerable
    end

    # Returns the wrapped enumerable as an array.
    #
    # This method provides direct access to the underlying enumerable's array
    # representation without any async processing. It's useful when you need
    # to materialize the collection after async operations.
    #
    # @return [Array] The enumerable converted to an array
    #
    # @example
    #   async_enum = [1, 2, 3].async
    #   async_enum.to_a  # => [1, 2, 3]
    #
    # @example After async operations
    #   result = data.async
    #                .select { |x| x.even? }
    #                .map { |x| x * 2 }
    #                .to_a  # Materializes the final result
    def to_a
      @enumerable.to_a
    end
  end
end
