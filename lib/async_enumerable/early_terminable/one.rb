# frozen_string_literal: true

require "async/barrier"
require "concurrent/atomic/atomic_fixnum"

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously checks if exactly one element satisfies the given
    # condition.
    #
    # Executes the block for each element in parallel and returns true if
    # exactly one element returns a truthy value. Short-circuits and returns
    # false as soon as a second match is found.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether the element satisfies the condition
    #
    # @return [Boolean] true if exactly one element satisfies the condition
    #
    # @example Check for single admin
    #   users.async.one? { |u| u.admin? }  # => true if exactly one admin
    #
    # @example With validation
    #   configs.async.one? { |c| c.primary? }
    #   # Validates all configs in parallel, ensures only one is primary
    def one?(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        count = Concurrent::AtomicFixnum.new(0)

        @enumerable.each do |item|
          break if count.value > 1

          barrier.async do
            if block.call(item)
              if count.increment > 1
                # Stop the barrier early when we have too many matches
                barrier.stop
              end
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        barrier.wait rescue Async::Stop

        count.value == 1
      end
    end
  end
end
