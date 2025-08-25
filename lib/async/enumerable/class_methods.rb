module Async
  module Enumerable
    module ClassMethods
      # Defines enumerable source for async operations.
      # @param collection_ref [Symbol] Method/ivar returning enumerable
      # @param kwargs [Hash] Configuration options (max_fibers, etc.)
      def def_async_enumerable(collection_ref = nil, **kwargs)
        # Create class-level config
        ops = {collection_ref:}.compact.merge(kwargs)
        @__async_enumerable_config_ref = Concurrent::AtomicReference.new(__async_enumerable_config.with(**ops))
      end

      def __async_enumerable_collection_ref
        __async_enumerable_config.collection_ref
      end

      # Class method to get config with proper precedence
      def __async_enumerable_config
        @__async_enumerable_config_ref&.get || Async::Enumerable.config
      end
    end
  end
end
