# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Sort
          # Async version of sort that returns an Async::Enumerator for chaining
          def sort(&block)
            self.class.new(super, max_fibers: @max_fibers)
          end
        end
      end
    end
  end
end
