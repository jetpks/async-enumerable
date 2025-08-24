# frozen_string_literal: true

module Async
  module Enumerable
    # Configuration data class for managing async enumerable settings.
    # Uses Ruby's Data class for immutability and clean API.
    class Config < Data.define(:max_fibers)
      DEFAULT_MAX_FIBERS = 1024

      # Creates a default configuration instance.
      # @return [Config] Default configuration with standard settings
      def self.default = new

      def initialize(max_fibers: DEFAULT_MAX_FIBERS) = super
    end
  end
end
