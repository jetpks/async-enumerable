# frozen_string_literal: true

module Async
  module Enumerable
    # Provides bounded concurrency control for async operations.
    # See docs/reference/fiber_limiter.md for detailed documentation.
    # @api private
    module FiberLimiter
      private

      # Executes block with bounded concurrency.
      # @param early_termination [Boolean] Support early stop
      # @yield [barrier] Barrier for spawning async tasks
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

      # Gets max fibers (instance or global default).
      # @return [Integer] Maximum concurrent fibers
      def max_fibers
        __async_enumerable_config&.max_fibers || Async::Enumerable.max_fibers
      end
    end
  end
end
