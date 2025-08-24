# frozen_string_literal: true

require "async/barrier"
require "concurrent/atomic/atomic_boolean"

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
    def all?(&block)
      return super unless block_given?

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
        barrier.wait rescue Async::Stop

        !failed.true?
      end
    end
  end
end
