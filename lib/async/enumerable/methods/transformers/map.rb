# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Map
          def self.included(base) = base.include(Each) # Dependency

          # Maps elements in parallel, returns async enumerator.
          # @yield [item] Transform for each element
          # @return [Async::Enumerator] Transformed collection
          def map(&block)
            return enum_for(__method__) unless block_given?
            Async::Enumerator.new(super, __async_enumerable_config)
          end
          alias_method :collect, :map
        end
      end
    end
  end
end
