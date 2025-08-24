# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Uniq
          # Async version of uniq that returns an Async::Enumerator for chaining
          def uniq(&block)
            self.class.new(super, max_fibers: @max_fibers)
          end
        end
      end
    end
  end
end
