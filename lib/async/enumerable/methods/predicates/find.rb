# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module Find
          # Returns first element that satisfies condition (parallel, early termination).
          # @yield [item] Test condition for each element
          # @return [Object, nil] First matching element or nil
          def find(ifnone = nil, &block)
            return super unless block_given?

            result = Concurrent::AtomicReference.new(nil)

            with_bounded_concurrency(early_termination: true) do |barrier|
              enumerable_source.each do |item|
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

          # Alias for find.
          alias_method :detect, :find
        end
      end
    end
  end
end
