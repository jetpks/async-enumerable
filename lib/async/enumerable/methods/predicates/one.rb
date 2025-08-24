# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module One
          # Returns true if exactly one element satisfies the condition (parallel).
          # @yield [item] Test condition for each element
          # @return [Boolean] true if exactly one element matches
          def one?(pattern = nil, &block)
            # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
            if pattern
              return enumerable_source.one?(pattern)
            elsif !block_given?
              return enumerable_source.one?
            end

            count = Concurrent::AtomicFixnum.new(0)

            with_bounded_concurrency(early_termination: true) do |barrier|
              enumerable_source.each do |item|
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
            end

            count.value == 1
          end
        end
      end
    end
  end
end
