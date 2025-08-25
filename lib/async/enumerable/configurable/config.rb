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

        # returns a materialized struct of the current config -- used in
        # Async::Enumerable.configure
        def to_struct
          Struct
            .new("ConfigStruct", *members)
            .new(*deconstruct)
        end
      end
    end
  end
end
