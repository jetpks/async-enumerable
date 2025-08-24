# frozen_string_literal: true

require "async/barrier"
require "concurrent/array"

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously takes the first n elements from the enumerable.
    #
    # Processes only the first n elements in parallel, avoiding unnecessary
    # work on remaining elements. Results are returned in order despite
    # parallel execution.
    #
    # @param n [Integer] Number of elements to take
    #
    # @return [Array] Array containing the first n elements (or fewer if
    #   the enumerable has less than n elements)
    #
    # @example Take first 10 elements
    #   (1..100).async.take(10)  # => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    #
    # @example With processing
    #   urls.async.take(5).map { |url| fetch(url) }
    #   # Fetches only the first 5 URLs in parallel
    def take(n)
      raise ArgumentError, "attempt to take negative size" if n < 0
      return [] if n == 0

      Sync do |parent|
        # Use a barrier to collect exactly n results
        barrier = Async::Barrier.new(parent:)
        results = Concurrent::Array.new

        @enumerable.each_with_index do |item, index|
          break if index >= n

          barrier.async do
            results[index] = item
          end
        end

        # Wait for all spawned tasks
        barrier.wait

        # Convert to regular array for compatibility
        results.to_a
      end
    end
  end
end
