# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module FindIndex
          def self.included(base)
            base.include(::Enumerable) # Dependency
            base.include(CollectionResolver) # Dependency
            base.include(ConcurrencyBounder) # Dependency
          end

          # Returns index of first matching element (parallel, early termination).
          # @note Returns the index of the **fastest completing** match, not necessarily the first by position.
          #   Due to parallel execution, whichever element completes evaluation first will have its index returned.
          #   Use synchronous `find_index` if positional order matters.
          # @param value [Object] Value to find or omit for block form
          # @return [Integer, nil] Index of first match or nil
          def find_index(value = (no_value = true), &block)
            if no_value && !block_given?
              return enum_for(__method__)
            end

            result_index = Concurrent::AtomicReference.new(nil)

            __async_enumerable_bounded_concurrency(early_termination: true) do |barrier|
              __async_enumerable_collection.each_with_index do |item, index|
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
            end

            result_index.get
          end
        end
      end
    end
  end
end
