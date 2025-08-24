# frozen_string_literal: true

require "async/barrier"
require "async/semaphore"
require "concurrent/atomic/atomic_boolean"
require "concurrent/atomic/atomic_fixnum"
require "concurrent/array"

module AsyncEnumerable
  # EarlyTerminable module provides optimized asynchronous implementations for
  # enumerable methods that can terminate early.
  #
  # This module includes async versions of predicate methods (all?, any?, none?, one?),
  # find operations (find, find_index, include?), and take operations (first, take,
  # take_while). These methods are optimized to stop processing as soon as the result
  # is determined, avoiding unnecessary computation.
  #
  # The implementations use atomic variables from the concurrent-ruby gem to ensure
  # thread-safe operation when multiple async tasks are running concurrently. The
  # Async::Barrier#stop method is used to cancel remaining tasks once a result is found.
  #
  # @see AsyncEnumerator
  module EarlyTerminable
    # @!group Predicate Methods

    # Asynchronously checks if all elements satisfy the given condition.
    #
    # Executes the block for each element in parallel and returns true if all
    # elements return a truthy value. Short-circuits and returns false as soon
    # as any element returns a falsy value.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether the element satisfies the condition
    #
    # @return [Boolean] true if all elements satisfy the condition, false otherwise
    #
    # @example Check if all numbers are positive
    #   [1, 2, 3].async.all? { |n| n > 0 }  # => true
    #   [1, -2, 3].async.all? { |n| n > 0 } # => false (stops after -2)
    #
    # @example With expensive operations
    #   urls.async.all? { |url| validate_url(url) }
    #   # Validates all URLs in parallel, stops on first invalid
    def all?(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        failed = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if failed.true?

          barrier.async do
            unless block.call(item)
              failed.make_true
              # Stop the barrier early when we find a failure
              barrier.stop
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        barrier.wait rescue Async::Stop

        !failed.true?
      end
    end

    # Asynchronously checks if any element satisfies the given condition.
    #
    # Executes the block for each element in parallel and returns true as soon
    # as any element returns a truthy value. Short-circuits and stops processing
    # remaining elements once a match is found.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether the element satisfies the condition
    #
    # @return [Boolean] true if any element satisfies the condition, false otherwise
    #
    # @example Check if any number is negative
    #   [1, 2, -3].async.any? { |n| n < 0 }  # => true (stops after -3)
    #   [1, 2, 3].async.any? { |n| n < 0 }   # => false
    #
    # @example With API calls
    #   servers.async.any? { |server| server_responding?(server) }
    #   # Checks all servers in parallel, returns true on first response
    def any?(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        found = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if found.true?

          barrier.async do
            if block.call(item)
              found.make_true
              # Stop the barrier early when we find a match
              barrier.stop
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        barrier.wait rescue Async::Stop

        found.true?
      end
    end

    # Asynchronously checks if no elements satisfy the given condition.
    #
    # This is the inverse of #any?. Returns true if no element returns a
    # truthy value from the block. Short-circuits and returns false as soon
    # as any element returns truthy.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether the element satisfies the condition
    #
    # @return [Boolean] true if no elements satisfy the condition, false otherwise
    #
    # @example Check if no errors exist
    #   results.async.none? { |r| r.error? }  # => true if no errors
    #
    # @see #any?
    def none?(&block)
      !any?(&block)
    end

    # Asynchronously checks if exactly one element satisfies the given condition.
    #
    # Executes the block for each element in parallel and returns true if exactly
    # one element returns a truthy value. Short-circuits and returns false as soon
    # as a second match is found.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether the element satisfies the condition
    #
    # @return [Boolean] true if exactly one element satisfies the condition
    #
    # @example Check for single admin
    #   users.async.one? { |u| u.admin? }  # => true if exactly one admin
    #
    # @example With validation
    #   configs.async.one? { |c| c.primary? }
    #   # Validates all configs in parallel, ensures only one is primary
    def one?(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        count = Concurrent::AtomicFixnum.new(0)

        @enumerable.each do |item|
          break if count.value > 1

          barrier.async do
            if block.call(item)
              if count.increment > 1
                # Stop the barrier early when we have too many matches
                barrier.stop
              end
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        barrier.wait rescue Async::Stop

        count.value == 1
      end
    end

    # Asynchronously checks if the enumerable includes the given object.
    #
    # Searches for the object in parallel across all elements. Short-circuits
    # and returns true as soon as a matching element is found.
    #
    # @param obj The object to search for
    #
    # @return [Boolean] true if the object is found, false otherwise
    #
    # @example Check for inclusion
    #   [1, 2, 3].async.include?(2)  # => true
    #   large_dataset.async.include?(target)
    #   # Searches in parallel, stops on first match
    def include?(obj)
      any? { |item| item == obj }
    end

    # Alias for #include?
    # @see #include?
    alias_method :member?, :include?

    # @!group Find Methods

    # Asynchronously finds the first element that satisfies the given condition.
    #
    # Executes the block for each element in parallel and returns the first
    # element for which the block returns truthy. Short-circuits and stops
    # processing remaining elements once a match is found.
    #
    # Uses atomic compare-and-set to ensure only the first match is returned
    # when multiple async tasks find matches simultaneously.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether this is the element to find
    #
    # @return [Object, nil] The first matching element, or nil if none found
    #
    # @example Find first valid record
    #   records.async.find { |r| r.valid? && r.active? }
    #
    # @example With expensive computation
    #   datasets.async.find { |data| expensive_analysis(data) > threshold }
    #   # Analyzes all datasets in parallel, returns first match
    def find(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        result = Concurrent::AtomicReference.new(nil)

        @enumerable.each do |item|
          break unless result.get.nil?

          barrier.async do
            if block.call(item)
              # Use compare_and_set to ensure only the first match wins
              if result.compare_and_set(nil, item)
                # Stop the barrier early when we find a match
                barrier.stop
              end
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        barrier.wait rescue Async::Stop

        result.get
      end
    end

    # Alias for #find
    # @see #find
    alias_method :detect, :find

    # Asynchronously finds the index of the first element that matches.
    #
    # Can be called with either a value to search for or a block to test elements.
    # Executes in parallel and returns the index of the first match. Short-circuits
    # once a match is found.
    #
    # Uses atomic compare-and-set to ensure the lowest index is returned when
    # multiple matches are found simultaneously.
    #
    # @overload find_index(value)
    #   @param value The value to search for
    #   @return [Integer, nil] Index of the first occurrence of value
    #
    # @overload find_index(&block)
    #   @yield [item] Block to test each element
    #   @yieldparam item Each element from the enumerable
    #   @yieldreturn [Boolean] Whether this element matches
    #   @return [Integer, nil] Index of the first matching element
    #
    # @example Find index by value
    #   ['a', 'b', 'c'].async.find_index('b')  # => 1
    #
    # @example Find index by condition
    #   numbers.async.find_index { |n| n.prime? }
    #   # Checks all numbers in parallel, returns index of first prime
    def find_index(value = nil, &block)
      if value.nil? && !block_given?
        return super
      end

      Sync do |parent|
        barrier = Async::Barrier.new(parent:)
        result_index = Concurrent::AtomicReference.new(nil)

        @enumerable.each_with_index do |item, index|
          break unless result_index.get.nil?

          barrier.async do
            match = value.nil? ? block.call(item) : (item == value)
            if match
              # Use compare_and_set to ensure only the first match wins
              if result_index.compare_and_set(nil, index)
                # Stop the barrier early when we find a match
                barrier.stop
              end
            end
          end
        end

        # Wait for all tasks or until barrier is stopped early
        barrier.wait rescue Async::Stop

        result_index.get
      end
    end

    # @!group Take Methods

    # Returns the first element or first n elements from the enumerable.
    #
    # When called without arguments, returns the first element synchronously.
    # When called with n, delegates to #take for parallel processing of the
    # first n elements.
    #
    # @overload first
    #   @return [Object, nil] The first element, or nil if empty
    #
    # @overload first(n)
    #   @param n [Integer] Number of elements to return
    #   @return [Array] Array of the first n elements
    #
    # @example Get first element
    #   [1, 2, 3].async.first  # => 1
    #
    # @example Get first n elements
    #   data.async.first(5)  # Processes first 5 elements in parallel
    #
    # @see #take
    def first(n = nil)
      if n.nil?
        # Just get the first element synchronously
        @enumerable.first
      else
        # Get first n elements
        take(n)
      end
    end

    # Asynchronously takes the first n elements from the enumerable.
    #
    # Processes only the first n elements in parallel, avoiding unnecessary
    # work on remaining elements. Results are returned in order despite
    # parallel execution.
    #
    # @param n [Integer] Number of elements to take
    #
    # @return [Array] Array containing the first n elements (or fewer if
    #   the enumerable has less than n elements)
    #
    # @example Take first 10 elements
    #   (1..100).async.take(10)  # => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    #
    # @example With processing
    #   urls.async.take(5).map { |url| fetch(url) }
    #   # Fetches only the first 5 URLs in parallel
    def take(n)
      return [] if n <= 0

      Sync do |parent|
        # Use a barrier to collect exactly n results
        barrier = Async::Barrier.new(parent:)
        results = Concurrent::Array.new

        @enumerable.each_with_index do |item, index|
          break if index >= n

          barrier.async do
            results[index] = item
          end
        end

        # Wait for all spawned tasks
        barrier.wait

        # Convert to regular array for compatibility
        results.to_a
      end
    end

    # Takes elements while the block returns true.
    #
    # This method cannot be parallelized because it requires sequential
    # evaluation - we must check elements in order and stop at the first
    # false result. Delegates to the synchronous implementation.
    #
    # @yield [item] Block to test each element
    # @yieldparam item Each element from the enumerable
    # @yieldreturn [Boolean] Whether to continue taking elements
    #
    # @return [Array] Array of elements before the first false result
    #
    # @example
    #   [1, 2, 3, 4, 2].async.take_while { |n| n < 4 }  # => [1, 2, 3]
    #
    # @note This method executes synchronously as it requires sequential ordering
    def take_while(&block)
      # take_while needs sequential checking, so we can't parallelize
      # Defer to the synchronous implementation from Enumerable
      @enumerable.take_while(&block)
    end

    # @!group Other Methods

    # Returns a lazy enumerator for the wrapped enumerable.
    #
    # Returns the lazy enumerator from the underlying enumerable rather than
    # an async lazy enumerator, since lazy evaluation uses break statements
    # internally which are incompatible with async execution.
    #
    # @return [Enumerator::Lazy] A lazy enumerator for the wrapped enumerable
    #
    # @example
    #   data.async.lazy.select { |x| x.even? }.first(5)
    #   # Returns lazy enumerator from underlying enumerable
    #
    # @note The returned lazy enumerator will not have async capabilities
    def lazy
      @enumerable.lazy
    end
  end
end
