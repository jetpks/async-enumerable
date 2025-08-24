# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module FilterMap
          # Async version of filter_map that returns an Async::Enumerator for chaining
          def filter_map(&block)
            return enum_for(__method__) unless block_given?
            self.class.new(super, max_fibers: @max_fibers)
          end
        end
      end
    end
  end
end
