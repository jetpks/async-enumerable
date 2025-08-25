# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module None
          def self.included(base) = base.include(Any) # Dependency

          # Returns true if no elements satisfy the condition (parallel, early termination).
          # @yield [item] Test condition for each element
          # @return [Boolean] true if no elements match
          def none?(pattern = nil, &block)
            # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
            if pattern
              return __async_enumerable_collection.none?(pattern)
            elsif !block_given?
              return __async_enumerable_collection.none?
            end
            # For blocks, use our async any? and negate
            !any?(&block)
          end
        end
      end
    end
  end
end
