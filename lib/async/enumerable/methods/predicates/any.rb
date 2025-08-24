# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module Any
          # Returns true if any element satisfies the condition (parallel, early termination).
          # @yield [item] Test condition for each element
          # @return [Boolean] true if any element matches
          def any?(pattern = nil, &block)
            # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
            if pattern
              return enumerable_source.any?(pattern)
            elsif !block_given?
              return enumerable_source.any?
            end

            found = Concurrent::AtomicBoolean.new(false)

            with_bounded_concurrency(early_termination: true) do |barrier|
              enumerable_source.each do |item|
                break if found.true?

                barrier.async do
                  if block.call(item)
                    found.make_true
                    # Stop the barrier early when we find a match
                    barrier.stop
                  end
                end
              end
            end

            found.true?
          end
        end
      end
    end
  end
end
