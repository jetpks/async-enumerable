# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Iterators module for enumerable iteration helper methods.
      #
      # Currently, iteration helper methods are inherited from the standard
      # Enumerable module. These methods are inherently sequential and don't
      # benefit from async execution as they need to maintain order or state.
      #
      # Methods available through Enumerable:
      # - each_with_index: Iterates with index
      # - each_with_object: Iterates with an accumulator object
      # - each_cons: Iterates over consecutive n-element slices
      # - each_slice: Iterates over n-element slices
      # - cycle: Cycles through elements repeatedly
      # - with_index: Adds index to any enumerator
      #
      # These methods work correctly with async enumerables but execute
      # sequentially as their semantics require ordered processing.
      module Iterators
        # This module is intentionally empty as iteration methods
        # are inherited from Enumerable
      end
    end
  end
end
