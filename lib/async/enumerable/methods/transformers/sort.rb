# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Sort
          def self.included(base) = base.include(Each) # Dependency

          # Async version of sort that returns an Async::Enumerator for chaining
          def sort(&block)
            Async::Enumerator.new(super, __async_enumerable_config)
          end
        end
      end
    end
  end
end
