# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Iterators module for enumerable iteration helper methods.
      #
      # Iteration helper methods are inherited from the standard Enumerable
      # module. When used with async enumerables, these methods build on our
      # async #each implementation, though some maintain sequential semantics
      # where required by their nature.
      #
      # Methods available through Enumerable:
      # - each_with_index: Iterates with index (block executes async)
      # - each_with_object: Iterates with an accumulator object (block executes async)
      # - each_cons: Iterates over consecutive n-element slices (maintains order)
      # - each_slice: Iterates over n-element slices (block executes async per slice)
      # - cycle: Cycles through elements repeatedly (block executes async)
      # - with_index: Adds index to any enumerator
      module Iterators
        def self.included(base) = base.include(Each) # Dependency
        # This module is intentionally empty as iteration methods are
        # inherited from Enumerable
      end
    end
  end
end
