# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module All
          # Returns true if all elements satisfy the condition (parallel, early termination).
          # @yield [item] Test condition for each element
          # @return [Boolean] true if all elements match
          def all?(pattern = nil, &block)
            # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
            if pattern
              return enumerable_source.all?(pattern)
            elsif !block_given?
              return enumerable_source.all?
            end

            failed = Concurrent::AtomicBoolean.new(false)

            with_bounded_concurrency(early_termination: true) do |barrier|
              enumerable_source.each do |item|
                break if failed.true?

                barrier.async do
                  unless block.call(item)
                    failed.make_true
                    # Stop the barrier early when we find a failure
                    barrier.stop
                  end
                end
              end
            end

            !failed.true?
          end
        end
      end
    end
  end
end
