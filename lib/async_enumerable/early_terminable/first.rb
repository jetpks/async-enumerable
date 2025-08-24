# frozen_string_literal: true

module AsyncEnumerable
  module EarlyTerminable
    # Returns the first element or first n elements from the enumerable.
    #
    # When called without arguments, returns the first element synchronously.
    # When called with n, delegates to #take for parallel processing of the
    # first n elements.
    #
    # @overload first
    #   @return [Object, nil] The first element, or nil if empty
    #
    # @overload first(n)
    #   @param n [Integer] Number of elements to return
    #   @return [Array] Array of the first n elements
    #
    # @example Get first element
    #   [1, 2, 3].async.first  # => 1
    #
    # @example Get first n elements
    #   data.async.first(5)  # Processes first 5 elements in parallel
    #
    # @see #take
    def first(n = nil)
      if n.nil?
        # Just get the first element synchronously
        @enumerable.first
      else
        raise ArgumentError, "attempt to take negative size" if n < 0
        # Get first n elements
        take(n)
      end
    end
  end
end
