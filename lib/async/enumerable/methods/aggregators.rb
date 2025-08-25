# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Aggregators module for enumerable aggregation methods.
      #
      # Aggregation methods like reduce, inject, sum, count, and tally are
      # inherited from the standard Enumerable module. When used with async
      # enumerables, these methods automatically benefit from parallel execution
      # through our async #each implementation.
      #
      # The block passed to these methods (when applicable) executes concurrently
      # for each element, though the aggregation itself maintains correct ordering
      # and thread-safe accumulation.
      #
      # Methods available through Enumerable:
      # - reduce/inject: Combines elements using a binary operation
      # - sum: Calculates the sum of elements (block executes async)
      # - count: Counts elements matching a condition (block executes async)
      # - tally: Counts occurrences of each element
      # - min/max/minmax: Finds minimum/maximum elements (block executes async)
      # - min_by/max_by: Finds elements by computed values (block executes async)
      module Aggregators
        def self.included(base)
          base.include(Each) # Dependency
          base.include(CollectionResolver) # Dependency

          # Delegate non-parallelizable aggregator methods directly to the collection
          base.extend(Forwardable)
          # is lazy really an aggregator? no, but i don't want to figure out
          # _what_ it is either
          base.def_delegators :__async_enumerable_collection, :size, :length, :lazy
        end
        # This module is intentionally empty as aggregation methods are
        # inherited from Enumerable and automatically use our async #each
      end
    end
  end
end
