# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module One
          def self.included(base)
            base.include(::Enumerable) # Dependency
            base.include(CollectionResolver) # Dependency
            base.include(ConcurrencyBounder) # Dependency
          end

          # Returns true if exactly one element satisfies the condition (parallel).
          # @yield [item] Test condition for each element
          # @return [Boolean] true if exactly one element matches
          def one?(pattern = nil, &block)
            # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
            if pattern
              return __async_enumerable_collection.one?(pattern)
            elsif !block_given?
              return __async_enumerable_collection.one?
            end

            count = Concurrent::AtomicFixnum.new(0)

            __async_enumerable_bounded_concurrency(early_termination: true) do |barrier|
              __async_enumerable_collection.each do |item|
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
