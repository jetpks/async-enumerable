# frozen_string_literal: true

require "async/enumerable/methods/converters/to_a"
require "async/enumerable/methods/converters/sync"

module Async
  module Enumerable
    module Methods
      # Converters contains async implementations of enumerable conversion methods
      # that convert collections to other data types.
      module Converters
        include ToA
        include Sync
      end
    end
  end
end
