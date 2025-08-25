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
        def self.included(base)
          base.include Compact
          base.include FilterMap
          base.include FlatMap
          base.include Map
          base.include Reject
          base.include Select

          base.include Sort
          base.include SortBy
          base.include Uniq
        end
      end
    end
  end
end
