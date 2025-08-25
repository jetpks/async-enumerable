# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module SortBy
          def self.included(base) = base.include(Each) # Dependency

          # Async version of sort_by that returns an Async::Enumerator for chaining
          def sort_by(&block)
            return enum_for(__method__) unless block_given?
            Async::Enumerator.new(super, __async_enumerable_config)
          end
        end
      end
    end
  end
end
