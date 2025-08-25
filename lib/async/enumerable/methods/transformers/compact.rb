# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Compact
          def self.included(base) = base.include(Each) # Dependency

          # Async version of compact that returns an Async::Enumerator for chaining
          def compact
            Async::Enumerator.new(super, __async_enumerable_config)
          end
        end
      end
    end
  end
end
