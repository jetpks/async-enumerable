# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Slicers module for enumerable slicing and filtering methods.
      #
      # Slicing and filtering methods are inherited from the standard Enumerable
      # module. When used with async enumerables, methods that accept blocks
      # automatically benefit from parallel execution through our async #each
      # implementation.
      #
      # Methods available through Enumerable:
      # - drop/drop_while: Drops elements from the beginning (block executes async)
      # - take/take_while: Takes elements from the beginning (delegated for efficiency)
      # - grep/grep_v: Filters elements matching/not matching a pattern (block executes async)
      # - partition: Splits into two arrays based on a predicate (block executes async)
      # - chunk/chunk_while: Groups consecutive elements (maintains order)
      # - slice_before/slice_after/slice_when: Slices based on conditions (block executes async)
      module Slicers
        def self.included(base)
          base.include(Each) # Dependency
          base.include(CollectionResolver) # Dependency

          # Delegate non-parallelizable slicer methods directly to the collection
          base.extend(Forwardable)
          base.def_delegators :__async_enumerable_collection, :first, :take, :take_while
        end
        # This module is intentionally empty as slicing methods are
        # inherited from Enumerable and automatically use our async #each
      end
    end
  end
end
