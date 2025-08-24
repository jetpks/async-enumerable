# frozen_string_literal: true

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously finds an element that satisfies the given condition.
    #
    # Executes the block for each element in parallel and returns an element
    # for which the block returns truthy. Short-circuits and stops processing
    # remaining elements once a match is found.
    #
    # Note: Due to parallel execution, this may not return the first matching
    # element by position. It returns whichever matching element's check
    # completes first. For guaranteed first match, use the synchronous version
    # on the wrapped enumerable.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether this is the element to find
    #
    # @return [Object, nil] A matching element, or nil if none found
    #
    # @example Find first valid record
    #   records.async.find { |r| r.valid? && r.active? }
    #
    # @example With expensive computation
    #   datasets.async.find { |data| expensive_analysis(data) > threshold }
    #   # Analyzes all datasets in parallel, returns a match
    #   # (not necessarily the first by position due to parallel execution)
    def find(ifnone = nil, &block)
      return super unless block_given?

      result = Concurrent::AtomicReference.new(nil)

      with_bounded_concurrency(early_termination: true) do |barrier|
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
      end

      found = result.get
      if found.nil? && ifnone
        ifnone.call
      else
        found
      end
    end

    # Alias for #find
    # @see #find
    alias_method :detect, :find
  end
end
