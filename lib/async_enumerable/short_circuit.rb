# frozen_string_literal: true

require "async/barrier"
require "async/semaphore"
require "concurrent/atomic/atomic_boolean"
require "concurrent/atomic/atomic_fixnum"
require "concurrent/array"

module AsyncEnumerable
  module ShortCircuit
    # Predicates that short-circuit by stopping tasks early

    def all?(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)
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

    def any?(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)
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

    def none?(&block)
      !any?(&block)
    end

    def one?(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)
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

    def include?(obj)
      any? { |item| item == obj }
    end

    alias_method :member?, :include?

    # Find methods that short-circuit

    def find(&block)
      return super unless block_given?

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)
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

    alias_method :detect, :find

    def find_index(value = nil, &block)
      if value.nil? && !block_given?
        return super
      end

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)
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

    # Take methods - optimize by only spawning needed tasks

    def first(n = nil)
      if n.nil?
        # Just get the first element synchronously
        @enumerable.first
      else
        # Get first n elements
        take(n)
      end
    end

    def take(n)
      return [] if n <= 0

      Sync do |parent|
        # Use a barrier to collect exactly n results
        barrier = ::Async::Barrier.new(parent:)
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

    def take_while(&block)
      # take_while needs sequential checking, so we can't parallelize
      # Defer to the synchronous implementation from Enumerable
      @enumerable.take_while(&block)
    end

    # Override lazy to return a non-async lazy enumerator
    # since lazy uses breaks internally which don't work with async
    def lazy
      @enumerable.lazy
    end
  end
end
