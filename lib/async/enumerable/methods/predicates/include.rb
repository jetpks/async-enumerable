# frozen_string_literal: true

module Async
  module Enumerable
    module Methods
      module Predicates
        module Include
          def self.included(base) = base.include(Any) # Dependency

          # Checks if enumerable includes the object (parallel, early termination).
          # @param obj Object to search for
          # @return [Boolean] true if found
          def include?(obj)
            any? { |item| item == obj }
          end

          # Alias for include?.
          alias_method :member?, :include?
        end
      end
    end
  end
end
