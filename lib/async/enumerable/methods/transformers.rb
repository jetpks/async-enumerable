# frozen_string_literal: true

require "async/enumerable/methods/transformers/map"
require "async/enumerable/methods/transformers/select"
require "async/enumerable/methods/transformers/reject"
require "async/enumerable/methods/transformers/filter_map"
require "async/enumerable/methods/transformers/flat_map"
require "async/enumerable/methods/transformers/compact"
require "async/enumerable/methods/transformers/uniq"
require "async/enumerable/methods/transformers/sort"
require "async/enumerable/methods/transformers/sort_by"

module Async
  module Enumerable
    module Methods
      # Transformers contains async implementations of enumerable transformation methods
      # that transform collections into new collections.
      module Transformers
        include Map
        include Select
        include Reject
        include FilterMap
        include FlatMap
        include Compact
        include Uniq
        include Sort
        include SortBy
      end
    end
  end
end
