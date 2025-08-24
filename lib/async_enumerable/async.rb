# frozen_string_literal: true

module AsyncEnumerable
  # AsyncEnumerator is a wrapper class that provides asynchronous
  # implementations of Enumerable methods for parallel execution.
  #
  # This class wraps any Enumerable object and provides async versions of
  # standard enumerable methods. It includes the standard Enumerable module for
  # compatibility, as well as specialized async implementations through the
  # EarlyTerminable module.
  #
  # The AsyncEnumerator maintains a reference to the original enumerable and
  # delegates method calls while providing concurrent execution capabilities
  # through the async runtime.
  #
  # @example Creating an AsyncEnumerator
  #   async_enum = AsyncEnumerable::AsyncEnumerator.new([1, 2, 3, 4, 5])
  #   async_enum.map { |n| n * 2 }  # Executes in parallel
  #
  # @example Using through Enumerable#async
  #   # The preferred way to create an AsyncEnumerator
  #   result = [1, 2, 3].async.map { |n| slow_operation(n) }
  #
  # @see EarlyTerminable
  class AsyncEnumerator
    # Includes standard Enumerable for compatibility and method delegation
    include Enumerable

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
    # representation without any async processing. It's useful when you need to
    # materialize the collection after async operations.
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

    # Asynchronously iterates over each element in the enumerable, executing
    # the given block in parallel for each item.
    #
    # This method spawns async tasks for each item in the enumerable, allowing
    # them to execute concurrently. It uses an Async::Barrier to coordinate
    # the tasks and waits for all of them to complete before returning.
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

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)

        @enumerable.each do |item|
          barrier.async do
            block.call(item)
          end
        end

        barrier.wait
      end

      # Return self to allow chaining, like standard each
      self
    end
  end
end
