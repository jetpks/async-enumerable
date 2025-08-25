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
      __async_enumerable_configure do |cfg|
        cfg.to_h.merge(config.to_h, kwargs).each do |key, val|
          cfg[key] = val
        end
      end
    end
  end
end
