# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module Select
          # Async version of select that returns an Async::Enumerator for chaining
          def select(&block)
            return enum_for(__method__) unless block_given?
            self.class.new(super, max_fibers: @max_fibers)
          end
          alias_method :filter, :select
          alias_method :find_all, :select
        end
      end
    end
  end
end
