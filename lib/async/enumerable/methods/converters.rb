# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Methods that convert enumerables to other types.
      module Converters
        # Converts enumerable to array.
        # @return [Array] Array representation
        def to_a
          source = enumerable_source
          # If source is self, we need to use super to avoid infinite recursion
          if source == self
            super
          else
            source.to_a
          end
        end

        # Alias for to_a - materializes async chain results.
        # @return [Array] Array representation
        def sync
          to_a
        end
      end
    end
  end
end
