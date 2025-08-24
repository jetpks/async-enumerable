# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module SortBy
          # Async version of sort_by that returns an Async::Enumerator for chaining
          def sort_by(&block)
            return enum_for(__method__) unless block_given?
            self.class.new(super, max_fibers: @max_fibers)
          end
        end
      end
    end
  end
end
