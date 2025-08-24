# frozen_string_literal: true

module AsyncEnumerable
  # Each module provides the asynchronous implementation of the #each method.
  #
  # This module is included in AsyncEnumerator to provide parallel iteration
  # capabilities. It uses Async::Barrier to coordinate concurrent execution
  # of the block for each item in the enumerable.
  #
  # The async implementation ensures that all iterations are executed in parallel
  # while maintaining thread-safety through the async runtime's task management.
  #
  # @see AsyncEnumerator
  module Each
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
