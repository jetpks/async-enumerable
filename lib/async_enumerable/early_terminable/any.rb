# frozen_string_literal: true

require "async/barrier"
require "concurrent/atomic/atomic_boolean"

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously checks if any element satisfies the given condition.
    #
    # Executes the block for each element in parallel and returns true as soon
    # as any element returns a truthy value. Short-circuits and stops
    # processing remaining elements once a match is found.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether the element satisfies the condition
    #
    # @return [Boolean] true if any element satisfies the condition, false
    #   otherwise
    #
    # @example Check if any number is negative
    #   [1, 2, -3].async.any? { |n| n < 0 }  # => true (stops after -3)
    #   [1, 2, 3].async.any? { |n| n < 0 }   # => false
    #
    # @example With API calls
    #   servers.async.any? { |server| server_responding?(server) }
    #   # Checks all servers in parallel, returns true on first response
    def any?(pattern = nil, &block)
      # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
      if pattern
        return @enumerable.any?(pattern)
      elsif !block_given?
        return @enumerable.any?
      end

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        found = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if found.true?

          barrier.async do
            if block.call(item)
              found.make_true
              # Stop the barrier early when we find a match
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

        found.true?
      end
    end
  end
end
