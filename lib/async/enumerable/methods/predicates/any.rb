# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module Any
          # Asynchronously checks if any element satisfies the given condition.
          #
          # Executes the block for each element in parallel and returns true as
          # soon as any element returns a truthy value. Short-circuits and stops
          # processing remaining elements once a match is found.
          #
          # @yield [item] Block to test each element
          # @yieldparam item Each element from the enumerable
          # @yieldreturn [Boolean] Whether the element satisfies the condition
          #
          # @return [Boolean] true if any element satisfies the condition, false
          #   otherwise
          # @example Check if any number is negative
          #   [1, 2, -3].async.any? { |n| n < 0 }  # => true (stops after -3)
          #   [1, 2, 3].async.any? { |n| n < 0 }   # => false
          #
          # @example With API calls
          #   servers.async.any? { |server| server_responding?(server) }
          #   # Checks all servers in parallel, returns true on first response
          def any?(pattern = nil, &block)
            # Delegate pattern/no-block cases to wrapped enumerable to avoid break issues
            if pattern
              return enumerable_source.any?(pattern)
            elsif !block_given?
              return enumerable_source.any?
            end

            found = Concurrent::AtomicBoolean.new(false)

            with_bounded_concurrency(early_termination: true) do |barrier|
              enumerable_source.each do |item|
                break if found.true?

                barrier.async do
                  if block.call(item)
                    found.make_true
                    # Stop the barrier early when we find a match
                    barrier.stop
                  end
                end
              end
            end

            found.true?
          end
        end
      end
    end
  end
end
