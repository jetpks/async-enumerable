# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Map
          # Async version of map that returns an Async::Enumerator for chaining
          def map(&block)
            return enum_for(__method__) unless block_given?
            self.class.new(super, __async_enumerable_config)
          end
          alias_method :collect, :map
        end
      end
    end
  end
end
