# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Each
        def self.included(base)
          base.include(::Enumerable) # Dependency
          base.include(ConcurrencyBounder) # Dependency
          base.include(CollectionResolver) # Dependency
        end

        # Executes block for each element in parallel.
        #
        # This is the core of Async::Enumerable, as most of the enumerable
        # methods _require_ #each in order to function. This definition of each
        # is automatically included when `Async::Enumerable` is included, but it
        # can be overridden by the including class. Here be dragons, though.
        #
        # @yield [item] Block to run for each element
        # @return [self, Enumerator] Self for chaining or Enumerator without block
        def each(&block)
          return enum_for(__method__) unless block_given?

          __async_enumerable_bounded_concurrency do |barrier|
            __async_enumerable_collection.each do |item|
              barrier.async do
                block.call(item)
              end
            end
          end

          # Return self to allow chaining, like standard each
          self
        end
      end
    end
  end
end
