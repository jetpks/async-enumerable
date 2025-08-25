# frozen_string_literal: true

module Async
  module Enumerable
    # Manages configuration and collection resolution for async enumerables.
    # Provides a DSL for defining async enumerable sources and configuration.
    module Configurable
      # Configuration data class for managing async enumerable settings.
      # Uses Ruby's Data class for immutability and clean API.
      class Config < Data.define(:collection_ref, :max_fibers)
        DEFAULT_MAX_FIBERS = 1024

        def initialize(collection_ref: nil, max_fibers: DEFAULT_MAX_FIBERS)
          super
        end

        # Define the struct class once to avoid redefinition warnings
        ConfigStruct = Struct.new(*members)

        # Creates mutable struct for configuration editing.
        # @return [ConfigStruct] Mutable config struct
        def to_struct
          ConfigStruct.new(*deconstruct)
        end
      end

      class << self
        def included(base)
          unless base.instance_variable_get(:@__async_enumerable_config_ref)
            ref = Concurrent::AtomicReference.new
            base.instance_variable_set(:@__async_enumerable_config_ref, ref)
          end
        end
      end

      # Class methods for defining async enumerable sources
      module ClassMethods
        # Defines enumerable source for async operations.
        # @param collection_ref [Symbol] Method/ivar returning enumerable
        # @param kwargs [Hash] Configuration options (max_fibers, etc.)
        def def_async_enumerable(collection_ref = nil, **kwargs)
          # Store only the class-specific overrides, not a full config
          @__async_enumerable_class_overrides = {collection_ref:}.compact.merge(kwargs)
        end

        # Gets the collection reference from config.
        # @return [Symbol, nil] Collection reference
        def __async_enumerable_collection_ref
          __async_enumerable_config.collection_ref
        end

        # Gets config with class-level overrides merged.
        # @return [Config] Merged configuration
        def __async_enumerable_config
          # Dynamically merge module config with class overrides
          base = Async::Enumerable.config
          if @__async_enumerable_class_overrides
            base.with(**@__async_enumerable_class_overrides)
          else
            base
          end
        end

        # Returns nil as classes don't cache config refs.
        # @return [nil] Always nil for class level
        def __async_enumerable_config_ref
          nil
        end
      end

      # Instance methods for configuration and collection resolution

      # Gets or updates configuration with block.
      # @yield [ConfigStruct] Mutable config for editing
      # @return [Config] Current or updated configuration
      def __async_enumerable_configure
        # Get the current config (with hierarchy)
        if @__async_enumerable_config_ref
          current = @__async_enumerable_config_ref.get
        else
          # Build config from hierarchy
          current_hash = __async_enumerable_merge_all_config
          current = Config.new(**current_hash)
        end

        return current unless block_given?

        mutable = current.to_struct
        yield mutable
        final = __async_enumerable_merge_all_config(mutable.to_h)

        Config.new(**final).tap do |updated|
          @__async_enumerable_config_ref = Concurrent::AtomicReference.new(updated)
        end
      end
      alias_method :__async_enumerable_config, :__async_enumerable_configure

      # Merges configs from all hierarchy levels.
      # @param config [Hash, nil] Additional config to merge
      # @return [Hash] Merged configuration hash
      def __async_enumerable_merge_all_config(config = nil)
        [Async::Enumerable.config].tap do |arr|
          class_cfg = self.class.respond_to?(:__async_enumerable_config) ? self.class.__async_enumerable_config : nil

          arr << class_cfg
          arr << @__async_enumerable_config
          arr << config
        end.compact.map(&:to_h).reduce(&:merge)
      end

      # Gets the config reference for this object.
      # @return [AtomicReference] Config reference
      def __async_enumerable_config_ref
        # First check for instance-level config ref
        @__async_enumerable_config_ref || Async::Enumerable.config_ref
      end

      # Collection resolution methods

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
