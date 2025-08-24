# frozen_string_literal: true

require "async/enumerable/methods/transformers"
require "async/enumerable/methods/predicates"
require "async/enumerable/methods/aggregators"
require "async/enumerable/methods/converters"
require "async/enumerable/methods/iterators"
require "async/enumerable/methods/slicers"

module Async
  module Enumerable
    # Methods contains all async implementations of Enumerable methods,
    # organized into logical groups for better maintainability and selective inclusion.
    module Methods
      include Transformers
      include Predicates
      include Aggregators
      include Converters
      include Iterators
      include Slicers
    end
  end
end
