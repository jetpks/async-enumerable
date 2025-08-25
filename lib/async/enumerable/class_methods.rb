module Async
  module Enumerable
    module ClassMethods
      # Defines enumerable source for async operations.
      # @param collection_ref [Symbol] Method/ivar returning enumerable
      # @param kwargs [Hash] Configuration options (max_fibers, etc.)
      def def_async_enumerable(collection_ref = nil, **kwargs)
        # Store only the class-specific overrides, not a full config
        @__async_enumerable_class_overrides = {collection_ref:}.compact.merge(kwargs)
      end

      def __async_enumerable_collection_ref
        __async_enumerable_config.collection_ref
      end

      # Class method to get config with proper precedence
      def __async_enumerable_config
        # Dynamically merge module config with class overrides
        base = Async::Enumerable.config
        if @__async_enumerable_class_overrides
          base.with(**@__async_enumerable_class_overrides)
        else
          base
        end
      end

      def __async_enumerable_config_ref
        # Return nil to indicate no cached ref at class level
        nil
      end
    end
  end
end
