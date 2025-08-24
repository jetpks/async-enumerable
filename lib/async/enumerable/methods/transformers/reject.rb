# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Reject
          # Async version of reject that returns an Async::Enumerator for chaining
          def reject(&block)
            return enum_for(__method__) unless block_given?
            self.class.new(super, @async_enumerable_config)
          end
        end
      end
    end
  end
end
