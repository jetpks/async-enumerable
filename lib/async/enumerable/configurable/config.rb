# frozen_string_literal: true

module Async
  module Enumerable
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
    end
  end
end
