# frozen_string_literal: true

require "async/enumerable/methods/transformers/compact"
require "async/enumerable/methods/transformers/filter_map"
require "async/enumerable/methods/transformers/flat_map"
require "async/enumerable/methods/transformers/map"
require "async/enumerable/methods/transformers/reject"
require "async/enumerable/methods/transformers/select"

require "async/enumerable/methods/transformers/sort"
require "async/enumerable/methods/transformers/sort_by"
require "async/enumerable/methods/transformers/uniq"

module Async
  module Enumerable
    module Methods
      # Transformers contains async implementations of enumerable transformation methods
      # that transform collections into new collections.
      module Transformers
        include Compact
        include FilterMap
        include FlatMap
        include Map
        include Reject
        include Select

        include Sort
        include SortBy
        include Uniq
      end
    end
  end
end
