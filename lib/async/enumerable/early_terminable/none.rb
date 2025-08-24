# frozen_string_literal: true

module Async
  module Enumerable
    module EarlyTerminable
      # Asynchronously checks if no elements satisfy the given condition. This
      # is the inverse of #any?. Returns true if no element returns a truthy
      # value from the block. Short-circuits and returns false as soon as any
      # element returns truthy.
      #
      # @yield [item] Block to test each element
      # @yieldparam item Each element from the enumerable
      # @yieldreturn [Boolean] Whether the element satisfies the condition
      #
      # @return [Boolean] true if no elements satisfy the condition, false
      #   otherwise
      #
      # @example Check if no errors exist
      #   results.async.none? { |r| r.error? }  # => true if no errors
      #
      # @see #any?
      def none?(pattern = nil, &block)
        # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
        if pattern
          return @enumerable.none?(pattern)
        elsif !block_given?
          return @enumerable.none?
        end
        # For blocks, use our async any? and negate
        !any?(&block)
      end
    end
  end
end
