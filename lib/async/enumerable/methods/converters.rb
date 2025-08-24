# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      # Converters contains async implementations of enumerable conversion methods
      # that convert collections to other data types.
      module Converters
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

        # Synchronizes the async enumerable back to a regular array.
        # This is an alias for #to_a that provides a more semantic way to
        # end an async chain and get the results.
        #
        # @return [Array] The wrapped enumerable converted to an array
        #
        # @example Chaining with sync
        #   result = [:foo, :bar].async
        #                        .map { |sym| fetch_data(sym) }
        #                        .sync
        #   # => [<data for :foo>, <data for :bar>]
        #
        # @example Alternative to to_a
        #   data.async.select { |x| x.valid? }.sync  # same as .to_a
        def sync
          to_a
        end
      end
    end
  end
end
