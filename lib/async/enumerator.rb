# frozen_string_literal: true

module Async
  # Wrapper providing async enumerable methods for parallel execution.
  # See docs/reference/enumerator.md for detailed documentation.
  class Enumerator
    include Async::Enumerable
    def_async_enumerable :@enumerable

    # Creates async wrapper for enumerable.
    # @param enumerable [Enumerable] Object to wrap
    # @param config [Config, nil] Configuration object
    # @param kwargs [Hash] Configuration options (max_fibers, etc.)
    def initialize(enumerable = [], config = nil, **kwargs)
      @enumerable = enumerable

      # Only configure if config or kwargs are provided
      if config || !kwargs.empty?
        __async_enumerable_configure do |cfg|
          # Merge config if provided
          config&.to_h&.each do |key, val|
            cfg[key] = val if val
          end

          # Merge kwargs if provided
          kwargs.each do |key, val|
            cfg[key] = val if val
          end
        end
      end
    end
  end
end
