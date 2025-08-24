# frozen_string_literal: true

module AsyncEnumerable
  module EarlyTerminable
    # Takes elements while the block returns true.
    #
    # This method cannot be parallelized because it requires sequential
    # evaluation - we must check elements in order and stop at the first false
    # result. Delegates to the synchronous implementation.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether to continue taking elements
    #
    # @return [Array] Array of elements before the first false result
    #
    # @example
    #   [1, 2, 3, 4, 2].async.take_while { |n| n < 4 }  # => [1, 2, 3]
    #
    # @note This method executes synchronously as it requires sequential
    # ordering
    def take_while(&block)
      return enum_for(__method__) unless block_given?
      # take_while needs sequential checking, so we can't parallelize
      # Defer to the synchronous implementation from Enumerable
      @enumerable.take_while(&block)
    end
  end
end
