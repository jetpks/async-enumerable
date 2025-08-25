# frozen_string_literal: true

module Async
  module Enumerable
    # Provides helper methods to get the collection on which to enumerate
    module CollectionResolver
      def self.included(base)
        base.extend(ClassMethods) # Dependency
      end

      def __async_enumerable_collection_ref
        self.class.__async_enumerable_collection_ref
      end

      # Gets the enumerable source based on the context:
      # - For includable pattern with def_enumerator: calls the configured method
      # - For includable pattern without def_enumerator: returns self
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
