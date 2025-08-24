# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Aggregators module for enumerable aggregation methods.
      #
      # Currently, aggregation methods like reduce, inject, sum, count, and tally
      # are inherited from the standard Enumerable module. These methods don't
      # benefit from async execution as they require sequential processing or
      # final aggregation of results.
      #
      # Methods available through Enumerable:
      # - reduce/inject: Combines elements using a binary operation
      # - sum: Calculates the sum of elements
      # - count: Counts elements matching a condition
      # - tally: Counts occurrences of each element
      # - min/max/minmax: Finds minimum/maximum elements
      #
      # Future versions may implement async-aware aggregations for specific
      # use cases where partial aggregation can be parallelized.
      module Aggregators
        # This module is intentionally empty as aggregation methods
        # are inherited from Enumerable
      end
    end
  end
end
