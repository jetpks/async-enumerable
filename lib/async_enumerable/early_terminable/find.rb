# frozen_string_literal: true

require "async/barrier"
require "concurrent/atomic/atomic_reference"

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously finds the first element that satisfies the given
    # condition.
    #
    # Executes the block for each element in parallel and returns the first
    # element for which the block returns truthy. Short-circuits and stops
    # processing remaining elements once a match is found.
    #
    # Uses atomic compare-and-set to ensure only the first match is returned
    # when multiple async tasks find matches simultaneously.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether this is the element to find
    #
    # @return [Object, nil] The first matching element, or nil if none found
    #
    # @example Find first valid record
    #   records.async.find { |r| r.valid? && r.active? }
    #
    # @example With expensive computation
    #   datasets.async.find { |data| expensive_analysis(data) > threshold }
    #   # Analyzes all datasets in parallel, returns first match
    def find(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        result = Concurrent::AtomicReference.new(nil)

        @enumerable.each do |item|
          break unless result.get.nil?

          barrier.async do
            if block.call(item)
              # Use compare_and_set to ensure only the first match wins
              if result.compare_and_set(nil, item)
                # Stop the barrier early when we find a match
                barrier.stop
              end
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        barrier.wait rescue Async::Stop

        result.get
      end
    end

    # Alias for #find
    # @see #find
    alias_method :detect, :find
  end
end
