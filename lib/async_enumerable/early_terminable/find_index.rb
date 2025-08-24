# frozen_string_literal: true

require "async/barrier"
require "concurrent/atomic/atomic_reference"

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously finds the index of an element that matches.
    #
    # Can be called with either a value to search for or a block to test
    # elements. Executes in parallel and returns the index of a matching element.
    # Short-circuits once a match is found.
    #
    # Note: Due to parallel execution, this may not return the lowest index
    # when multiple elements match. It returns the index of whichever matching
    # element completes first. For guaranteed lowest index, use the synchronous
    # version on the wrapped enumerable.
    #
    # @overload find_index(value)
    #   @param value The value to search for
    #   @return [Integer, nil] Index of the first occurrence of value
    #
    # @overload find_index(&block)
    #   @yield [item] Block to test each element
    #   @yieldparam item Each element from the enumerable
    #   @yieldreturn [Boolean] Whether this element matches
    #   @return [Integer, nil] Index of the first matching element
    #
    # @example Find index by value
    #   ['a', 'b', 'c'].async.find_index('b')  # => 1
    #
    # @example Find index by condition
    #   numbers.async.find_index { |n| n.prime? }
    #   # Checks all numbers in parallel, returns index of a prime number
    #   # (not necessarily the first prime due to parallel execution)
    def find_index(value = (no_value = true), &block)
      if no_value && !block_given?
        return enum_for(__method__)
      end

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        result_index = Concurrent::AtomicReference.new(nil)

        @enumerable.each_with_index do |item, index|
          break unless result_index.get.nil?

          barrier.async do
            match = no_value ? block.call(item) : (item == value)
            if match
              # Use compare_and_set to ensure only the first match wins
              if result_index.compare_and_set(nil, index)
                # Stop the barrier early when we find a match
                barrier.stop
              end
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        begin
          barrier.wait
        rescue Async::Stop
          # Expected when barrier.stop is called for early termination
        end

        result_index.get
      end
    end
  end
end
