# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module Any
          def self.included(base)
            base.include(::Enumerable) # Dependency
            base.include(CollectionResolver) # Dependency
            base.include(ConcurrencyBounder) # Dependency
          end

          # Returns true if any element satisfies the condition (parallel, early termination).
          # @yield [item] Test condition for each element
          # @return [Boolean] true if any element matches
          def any?(pattern = nil, &block)
            # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
            if pattern
              return __async_enumerable_collection.any?(pattern)
            elsif !block_given?
              return __async_enumerable_collection.any?
            end

            found = Concurrent::AtomicBoolean.new(false)

            __async_enumerable_bounded_concurrency(early_termination: true) do |barrier|
              __async_enumerable_collection.each do |item|
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
