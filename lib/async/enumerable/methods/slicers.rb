# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Slicers module for enumerable slicing and filtering methods.
      #
      # Currently, slicing and filtering methods are inherited from the standard
      # Enumerable module. While some of these could potentially benefit from
      # async execution (like partition with expensive predicates), the current
      # implementation uses the sequential versions for simplicity.
      #
      # Methods available through Enumerable:
      # - drop/drop_while: Drops elements from the beginning
      # - take/take_while: Takes elements from the beginning (delegated)
      # - grep/grep_v: Filters elements matching/not matching a pattern
      # - partition: Splits into two arrays based on a predicate
      # - chunk/chunk_while: Groups consecutive elements
      # - slice_before/slice_after/slice_when: Slices based on conditions
      #
      # Future versions may implement async-aware versions of methods like
      # partition where the predicate evaluation could be parallelized.
      module Slicers
        # This module is intentionally empty as slicing methods
        # are inherited from Enumerable
      end
    end
  end
end
