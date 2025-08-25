# frozen_string_literal: true

require "async/enumerable/collection_resolver"

require "async/enumerable/methods/each"

require "async/enumerable/methods/aggregators"
require "async/enumerable/methods/converters"
require "async/enumerable/methods/iterators"
require "async/enumerable/methods/predicates"
require "async/enumerable/methods/slicers"
require "async/enumerable/methods/transformers"

module Async
  module Enumerable
    # Methods contains all async implementations of Enumerable methods
    module Methods
      include CollectionResolver

      include Each

      include Aggregators
      include Converters
      include Iterators
      include Predicates
      include Slicers
      include Transformers
    end
  end
end
