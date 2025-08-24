# frozen_string_literal: true

require "forwardable"
require "async/enumerable/bounded_concurrency"

module Async
  # Enumerator is a wrapper class that provides asynchronous
  # implementations of Enumerable methods for parallel execution.
  #
  # This class wraps any Enumerable object and provides async versions of
  # standard enumerable methods. It includes the standard Enumerable module
  # for compatibility, as well as specialized async implementations through
  # the EarlyTerminable module.
  #
  # The Enumerator maintains a reference to the original enumerable and
  # delegates method calls while providing concurrent execution capabilities
  # through the async runtime.
  #
  # @example Creating an Async::Enumerator
  #   async_enum = Async::Enumerator.new([1, 2, 3, 4, 5])
  #   async_enum.map { |n| n * 2 }  # Executes in parallel
  #
  # @example Using through Enumerable#async
  #   # The preferred way to create an Async::Enumerator
  #   result = [1, 2, 3].async.map { |n| slow_operation(n) }
  #
  # @example With custom fiber limit
  #   huge_dataset.async(max_fibers: 100).map { |n| process(n) }
  #
  # @see Enumerable::EarlyTerminable
  class Enumerator
    extend Forwardable
    include ::Enumerable
    include Comparable
    include Enumerable::BoundedConcurrency
    include Enumerable::EarlyTerminable

    # Delegate methods that are inherently sequential back to the wrapped enumerable
    def_delegators :@enumerable, :first, :take, :take_while, :lazy, :size, :length

    # Creates a new Async::Enumerator wrapping the given enumerable.
    #
    # @param enumerable [Enumerable] Any object that includes Enumerable
    #
    # @param max_fibers [Integer, nil] Maximum number of concurrent fibers,
    #   defaults to Async::Enumerable.max_fibers
    #
    # @example Default fiber limit
    #   async_array = Async::Enumerator.new([1, 2, 3])
    #
    # @example Custom fiber limit
    #   async_range = Async::Enumerator.new(1..100, max_fibers: 50)
    def initialize(enumerable, max_fibers: nil)
      @enumerable = enumerable
      @max_fibers = max_fibers
    end

    # Returns the wrapped enumerable as an array.
    #
    # This method simply converts the wrapped enumerable to an array without
    # any async processing. Note that async operations like map and select
    # already return arrays.
    #
    # @return [Array] The wrapped enumerable converted to an array
    #
    # @example
    #   async_enum = (1..3).async
    #   async_enum.to_a  # => [1, 2, 3]
    #
    # @example Converting a Set
    #   async_set = Set[1, 2, 3].async
    #   async_set.to_a  # => [1, 2, 3] (order may vary)
    def to_a
      @enumerable.to_a
    end

    # Synchronizes the async enumerable back to a regular array.
    # This is an alias for #to_a that provides a more semantic way to
    # end an async chain and get the results.
    #
    # @return [Array] The wrapped enumerable converted to an array
    #
    # @example Chaining with sync
    #   result = [:foo, :bar].async
    #                        .map { |sym| fetch_data(sym) }
    #                        .sync
    #   # => [<data for :foo>, <data for :bar>]
    #
    # @example Alternative to to_a
    #   data.async.select { |x| x.valid? }.sync  # same as .to_a
    alias_method :sync, :to_a

    # Asynchronously iterates over each element in the enumerable, executing
    # the given block in parallel for each item.
    #
    # This method spawns async tasks for each item in the enumerable,
    # allowing them to execute concurrently. It uses an Async::Barrier to
    # coordinate the tasks and waits for all of them to complete before
    # returning.
    #
    # When called without a block, returns an Enumerator for compatibility
    # with the standard Enumerable interface.
    #
    # @yield [item] Gives each element to the block in parallel
    # @yieldparam item The current item from the enumerable
    #
    # @return [self, Enumerator] Returns self when block given (for chaining),
    #   or an Enumerator when no block given
    #
    # @example Basic async iteration
    #   [1, 2, 3].async.each do |n|
    #     puts "Processing #{n}"
    #     sleep(1)  # All three will complete in ~1 second total
    #   end
    #
    # @example With I/O operations
    #   urls.async.each do |url|
    #     response = HTTP.get(url)
    #     save_to_cache(url, response)
    #   end
    #   # All URLs are fetched and cached concurrently
    #
    # @example Chaining
    #   data.async
    #       .each { |item| log(item) }
    #       .map { |item| transform(item) }
    #
    # @note The execution order of the block is not guaranteed to match
    #   the order of items in the enumerable due to parallel execution
    def each(&block)
      return enum_for(__method__) unless block_given?

      with_bounded_concurrency do |barrier|
        @enumerable.each do |item|
          barrier.async do
            block.call(item)
          end
        end
      end

      # Return self to allow chaining, like standard each
      self
    end

    # Compares this Async::Enumerator with another object.
    # Converts both to arrays for comparison.
    #
    # @param other [Object] The object to compare with
    # @return [Integer, nil] -1, 0, 1, or nil based on comparison
    #
    # @example Comparing with an array
    #   async_enum = [1, 2, 3].async
    #   async_enum <=> [1, 2, 3]  # => 0
    #   async_enum <=> [1, 2, 4]  # => -1
    def <=>(other)
      return nil unless other.respond_to?(:to_a)
      to_a <=> other.to_a
    end

    # Checks equality with another object.
    # Converts both to arrays for comparison.
    #
    # @param other [Object] The object to compare with
    # @return [Boolean] true if equal, false otherwise
    #
    # @example Testing equality with an array
    #   result = [1, 2, 3].async.map { |x| x * 2 }
    #   result == [2, 4, 6]  # => true
    def ==(other)
      return false unless other.respond_to?(:to_a)
      to_a == other.to_a
    end
    alias_method :eql?, :==

    # Override transformation methods to return Async::Enumerator for chaining

    # Async version of map that returns an Async::Enumerator for chaining
    def map(&block)
      return enum_for(__method__) unless block_given?
      new(super, max_fibers: @max_fibers)
    end
    alias_method :collect, :map

    # Async version of select that returns an Async::Enumerator for chaining
    def select(&block)
      return enum_for(__method__) unless block_given?
      new(super, max_fibers: @max_fibers)
    end
    alias_method :filter, :select
    alias_method :find_all, :select

    # Async version of reject that returns an Async::Enumerator for chaining
    def reject(&block)
      return enum_for(__method__) unless block_given?
      new(super, max_fibers: @max_fibers)
    end

    # Async version of filter_map that returns an Async::Enumerator for chaining
    def filter_map(&block)
      return enum_for(__method__) unless block_given?
      new(super, max_fibers: @max_fibers)
    end

    # Async version of flat_map that returns an Async::Enumerator for chaining
    def flat_map(&block)
      return enum_for(__method__) unless block_given?
      new(super, max_fibers: @max_fibers)
    end
    alias_method :collect_concat, :flat_map

    # Async version of compact that returns an Async::Enumerator for chaining
    def compact
      new(super, max_fibers: @max_fibers)
    end

    # Async version of uniq that returns an Async::Enumerator for chaining
    def uniq(&block)
      new(super, max_fibers: @max_fibers)
    end

    # Async version of sort that returns an Async::Enumerator for chaining
    def sort(&block)
      new(super, max_fibers: @max_fibers)
    end

    # Async version of sort_by that returns an Async::Enumerator for chaining
    def sort_by(&block)
      return enum_for(__method__) unless block_given?
      new(super, max_fibers: @max_fibers)
    end
  end
end
