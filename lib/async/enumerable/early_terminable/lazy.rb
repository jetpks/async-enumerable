# frozen_string_literal: true

module Async
  module Enumerable
    module EarlyTerminable
      # Returns a lazy enumerator for the wrapped enumerable.
      # Returns the lazy enumerator from the underlying enumerable rather than an
      # async lazy enumerator, since lazy evaluation uses break statements
      # internally which are incompatible with async execution.
      # @return [Enumerator::Lazy] A lazy enumerator for the wrapped enumerable
      # @example
      #   data.async.lazy.select { |x| x.even? }.first(5)
      #   # Returns lazy enumerator from underlying enumerable
      #
      # @note The returned lazy enumerator will not have async capabilities
      def lazy
        @enumerable.lazy
      end
    end
  end
end
