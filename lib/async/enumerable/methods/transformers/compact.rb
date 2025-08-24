# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Compact
          # Async version of compact that returns an Async::Enumerator for chaining
          def compact
            self.class.new(super, max_fibers: @max_fibers)
          end
        end
      end
    end
  end
end
