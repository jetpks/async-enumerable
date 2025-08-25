# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Transformers
        module FlatMap
          def self.included(base) = base.include(Each) # Dependency

          # Async version of flat_map that returns an Async::Enumerator for chaining
          def flat_map(&block)
            return enum_for(__method__) unless block_given?
            Async::Enumerator.new(super, __async_enumerable_config)
          end
          alias_method :collect_concat, :flat_map
        end
      end
    end
  end
end
