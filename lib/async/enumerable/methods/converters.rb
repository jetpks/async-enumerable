# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Methods that convert enumerables to other types.
      module Converters
        def self.included(base) = base.include(CollectionResolver)

        # Converts enumerable to array.
        # @return [Array] Array representation
        def to_a
          source = __async_enumerable_collection
          # If source is self, we need to use super to avoid infinite recursion
          (source == self) ? super : source.to_a
        end
        alias_method :sync, :to_a
      end
    end
  end
end
