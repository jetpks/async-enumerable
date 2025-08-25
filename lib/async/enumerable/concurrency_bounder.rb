# frozen_string_literal: true

module Async
  module Enumerable
    # Provides bounded concurrency control for async operations.
    # See docs/reference/concurrency_bounder.md for detailed documentation.
    # @api private
    module ConcurrencyBounder
      def self.included(base) = base.include(Configurable)

      # Executes block with bounded concurrency.
      # @param early_termination [Boolean] Support early stop
      # @yield [barrier] Barrier for spawning async tasks
      def __async_enumerable_bounded_concurrency(early_termination: false, limit: nil, &block)
        Sync do |parent|
          limit ||= __async_enumerable_config.max_fibers
          semaphore = Async::Semaphore.new(limit, parent:)
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
    end
  end
end
