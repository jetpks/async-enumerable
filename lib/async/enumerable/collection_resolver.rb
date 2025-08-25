# frozen_string_literal: true

module Async
  module Enumerable
    # Resolves the enumerable collection source.
    # @api private
    module CollectionResolver
      def self.included(base)
        base.extend(ClassMethods) # Dependency
      end

      # Gets collection reference from class.
      # @return [Symbol, nil] Collection reference
      def __async_enumerable_collection_ref
        self.class.__async_enumerable_collection_ref
      end

      # Resolves the actual enumerable collection.
      # @return [Enumerable] The collection to enumerate
      def __async_enumerable_collection
        return self unless __async_enumerable_collection_ref.is_a?(Symbol)

        ref = __async_enumerable_collection_ref
        if ref.to_s.start_with?("@")
          instance_variable_get(ref)
        else
          send(ref)
        end
      end
    end
  end
end
