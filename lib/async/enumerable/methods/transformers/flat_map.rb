# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module FlatMap
          # Async version of flat_map that returns an Async::Enumerator for chaining
          def flat_map(&block)
            return enum_for(__method__) unless block_given?
            self.class.new(super, max_fibers: @max_fibers)
          end
          alias_method :collect_concat, :flat_map
        end
      end
    end
  end
end
