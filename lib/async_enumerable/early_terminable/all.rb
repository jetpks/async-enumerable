# frozen_string_literal: true

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously checks if all elements satisfy the given condition.
    #
    # Executes the block for each element in parallel and returns true if all
    # elements return a truthy value. Short-circuits and returns false as soon
    # as any element returns a falsy value.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether the element satisfies the condition
    #
    # @return [Boolean] true if all elements satisfy the condition, false
    #   otherwise
    #
    # @example Check if all numbers are positive
    #   [1, 2, 3].async.all? { |n| n > 0 }  # => true
    #   [1, -2, 3].async.all? { |n| n > 0 } # => false (stops after -2)
    #
    # @example With expensive operations
    #   urls.async.all? { |url| validate_url(url) }
    #   # Validates all URLs in parallel, stops on first invalid
    def all?(pattern = nil, &block)
      # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
      if pattern
        return @enumerable.all?(pattern)
      elsif !block_given?
        return @enumerable.all?
      end

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        failed = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if failed.true?

          barrier.async do
            unless block.call(item)
              failed.make_true
              # Stop the barrier early when we find a failure
              barrier.stop
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        begin
          barrier.wait
        rescue Async::Stop
          # Expected when barrier.stop is called for early termination
        end

        !failed.true?
      end
    end
  end
end
