# frozen_string_literal: true

require "async"
require "async/barrier"
require "async/semaphore"

require "concurrent/array"
require "concurrent/atomic/atomic_boolean"
require "concurrent/atomic/atomic_fixnum"
require "concurrent/atomic/atomic_reference"

require "async/enumerable/fiber_limiter"
require "async/enumerable/methods"
require "async/enumerable/version"
require "async/enumerator"
require "enumerable/async"

module Async
  # Async::Enumerable provides asynchronous, parallel execution capabilities
  # for Ruby's Enumerable.
  #
  # This gem extends Ruby's Enumerable module with an `.async` method that
  # returns an AsyncEnumerator wrapper, enabling concurrent execution of
  # enumerable operations using the socketry/async library. This allows for
  # significant performance improvements when dealing with I/O-bound operations
  # or processing large collections.
  #
  # ## Features
  #
  # - Parallel execution of enumerable methods
  # - Thread-safe operation with atomic variables
  # - Optimized early-termination implementations for predicates and find
  #   operations
  # - Full compatibility with standard Enumerable interface
  # - Configurable concurrency limits to prevent unbounded fiber creation
  #
  # ## Usage
  #
  # @example Basic async enumeration
  #   [1, 2, 3, 4, 5].async.map { |n| n * 2 }
  #   # => [2, 4, 6, 8, 10] (processed in parallel)
  #
  # @example Async I/O operations
  #   urls = ["http://api1.com", "http://api2.com", "http://api3.com"]
  #   results = urls.async.map { |url| fetch_data(url) }
  #   # All URLs fetched concurrently
  #
  # @example Early termination optimization
  #   large_array.async.any? { |item| expensive_check(item) }
  #   # Stops as soon as one item returns true
  #
  # @example Chaining async operations
  #   data.async
  #       .select { |item| item.active? }
  #       .map { |item| transform(item) }
  #       .reject { |item| item.invalid? }
  #       .to_a
  #
  # @example Configuring maximum fiber limits
  #   # Set global default
  #   Async::Enumerable.max_fibers = 100
  #
  #   # Or per-instance
  #   huge_dataset.async(max_fibers: 50).map { |item| process(item) }
  #
  # @see Enumerable#async
  # @see Async::Enumerator
  module Enumerable
    DEFAULT_MAX_FIBERS = 1024

    class << self
      attr_writer :max_fibers

      # Gets the default maximum number of fibers for async operations.
      # Defaults to 1024 if not explicitly set.
      #
      # @return [Integer] The current maximum fiber limit
      def max_fibers
        @max_fibers ||= DEFAULT_MAX_FIBERS
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.include(Methods)      # Include all method groups
      base.include(FiberLimiter) # Include fiber limiting functionality
    end

    module ClassMethods
      # Define the source of enumeration for async operations
      #
      # @param method_name [Symbol] The name of the method or attribute that returns the enumerable
      # @param max_fibers [Integer, nil] Optional default max_fibers for this enumerator
      #
      # @example Basic usage
      #   class MyCollection
      #     include Async::Enumerable
      #     def_enumerator :items
      #
      #     def initialize
      #       @items = []
      #     end
      #
      #     attr_reader :items
      #   end
      #
      #   collection = MyCollection.new
      #   collection.items << 1 << 2 << 3
      #   collection.async.map { |x| x * 2 } # => [2, 4, 6]
      def def_enumerator(method_name, max_fibers: nil)
        @enumerable_source = method_name
        @default_max_fibers = max_fibers

        define_method :async do |**options|
          source = send(method_name)
          fiber_limit = options[:max_fibers] || self.class.default_max_fibers
          ::Async::Enumerator.new(source, max_fibers: fiber_limit)
        end
      end

      attr_reader :enumerable_source, :default_max_fibers
    end

    # Default async method when no def_enumerator is called
    # This allows including classes to call async on self
    def async(max_fibers: nil)
      if self.class.respond_to?(:enumerable_source) && self.class.enumerable_source
        source = send(self.class.enumerable_source)
        fiber_limit = max_fibers || self.class.default_max_fibers
      else
        # If no source is defined, assume self is enumerable
        source = self
        fiber_limit = max_fibers
      end
      ::Async::Enumerator.new(source, max_fibers: fiber_limit)
    end
  end
end
