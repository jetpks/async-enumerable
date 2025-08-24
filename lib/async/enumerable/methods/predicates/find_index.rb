# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module FindIndex
          # Returns index of first matching element (parallel, early termination).
          # @param value [Object] Value to find or omit for block form
          # @return [Integer, nil] Index of first match or nil
          def find_index(value = (no_value = true), &block)
            if no_value && !block_given?
              return enum_for(__method__)
            end

            result_index = Concurrent::AtomicReference.new(nil)

            with_bounded_concurrency(early_termination: true) do |barrier|
              enumerable_source.each_with_index do |item, index|
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
