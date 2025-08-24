# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Converters
        module Sync
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
end
