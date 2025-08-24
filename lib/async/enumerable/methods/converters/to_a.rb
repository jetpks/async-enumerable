# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Converters
        module ToA
          # Returns the wrapped enumerable as an array.
          #
          # This method simply converts the wrapped enumerable to an array without
          # any async processing. Note that async operations like map and select
          # already return arrays.
          #
          # @return [Array] The wrapped enumerable converted to an array
          #
          # @example
          #   async_enum = (1..3).async
          #   async_enum.to_a  # => [1, 2, 3]
          #
          # @example Converting a Set
          #   async_set = Set[1, 2, 3].async
          #   async_set.to_a  # => [1, 2, 3] (order may vary)
          def to_a
            @enumerable.to_a
          end
        end
      end
    end
  end
end
