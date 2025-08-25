# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Uniq
          def self.included(base) = base.include(Each) # Dependency

          # Async version of uniq that returns an Async::Enumerator for chaining
          def uniq(&block)
            Async::Enumerator.new(super, __async_enumerable_config)
          end
        end
      end
    end
  end
end
