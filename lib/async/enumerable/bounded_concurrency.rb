# frozen_string_literal: true

module Async
  module Enumerable
    # BoundedConcurrency provides a helper method for executing async
    # operations with a maximum fiber limit to prevent unbounded concurrency.
    #
    # This module is included in AsyncEnumerator to provide a consistent way to
    # limit the number of concurrent fibers created during async operations. It
    # uses Async::Semaphore to enforce the fiber limit.
    #
    # @api private
    module BoundedConcurrency
      private

      # Executes a block with bounded concurrency using a semaphore.
      #
      # This method sets up an Async::Semaphore to limit the number of
      # concurrent fibers, creates a barrier under that semaphore, and yields
      # the barrier to the block for spawning async tasks.
      #
      # @param early_termination [Boolean] Whether the operation supports
      #   early termination (expects Async::Stop exceptions)
      # @yield [barrier] Gives the barrier to use for spawning async tasks
      # @yieldparam barrier [Async::Barrier] The barrier for spawning tasks
      # @return The result of the block
      def with_bounded_concurrency(early_termination: false, &block)
        Sync do |parent|
          semaphore = Async::Semaphore.new(max_fibers, parent:)
          barrier = Async::Barrier.new(parent: semaphore)

          # Yield the barrier for task spawning
          yield barrier

          # Wait for all tasks to complete (or early termination)
          if early_termination
            begin
              barrier.wait
            rescue Async::Stop
              # Expected when barrier.stop is called for early termination
            end
          else
            barrier.wait
          end
        end
      end

      # Gets the maximum number of fibers for this instance.
      # Falls back to the module default if not set on the instance.
      #
      # @return [Integer] The maximum number of concurrent fibers
      def max_fibers
        @max_fibers || Async::Enumerable.max_fibers
      end
    end
  end
end
