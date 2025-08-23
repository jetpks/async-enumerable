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

      Sync do
        tasks = Concurrent::Array.new
        failed = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if failed.true?

          task = Async do
            unless block.call(item)
              failed.make_true
            end
          end
          tasks << task
        end

        # Wait for all spawned tasks or until one fails
        tasks.each do |task|
          begin
            task.wait
          rescue Async::Stop
            # Task was stopped, that's ok
          end

          # If we found a failure, stop remaining tasks
          if failed.true?
            tasks.each(&:stop)
            break
          end
        end

        !failed.true?
      end
    end

    def any?(&block)
      return super unless block_given?

      Sync do
        tasks = Concurrent::Array.new
        found = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if found.true?

          task = Async do
            if block.call(item)
              found.make_true
            end
          end
          tasks << task
        end

        # Wait for all spawned tasks or until one succeeds
        tasks.each do |task|
          # TODO: this is slow in cases where tasks near the end of the array
          # complete faster than tasks near the beginning of the array. we
          # *should* be able to use an Async::Condition here to detect when we
          # have a find, rather than doing the each(&:wait)
          begin
            task.wait
          rescue Async::Stop
            # Task was stopped, that's ok
          end

          # If we found a match, stop remaining tasks
          if found.true?
            tasks.each(&:stop)
            break
          end
        end

        found.true?
      end
    end

    def none?(&block)
      !any?(&block)
    end

    def one?(&block)
      return super unless block_given?

      Sync do
        tasks = Concurrent::Array.new
        count = Concurrent::AtomicFixnum.new(0)

        @enumerable.each do |item|
          break if count.value > 1

          task = Async do
            if block.call(item)
              count.increment
            end
          end
          tasks << task
        end

        # Wait for all tasks
        tasks.each do |task|
          begin
            task.wait
          rescue Async::Stop
            # Task was stopped, that's ok
          end

          # If we found too many, stop remaining tasks
          if count.value > 1
            tasks.each(&:stop)
            break
          end
        end

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

      Sync do
        tasks = Concurrent::Array.new
        result = Concurrent::AtomicReference.new(nil)

        @enumerable.each do |item|
          break unless result.get.nil?

          task = Async do
            if block.call(item)
              # Use compare_and_set to ensure only the first match wins
              result.compare_and_set(nil, item)
            end
          end
          tasks << task
        end

        # Wait for all spawned tasks or until one is found
        tasks.each do |task|
          begin
            task.wait
          rescue Async::Stop
            # Task was stopped, that's ok
          end

          # If we found something, stop remaining tasks
          unless result.get.nil?
            tasks.each(&:stop)
            break
          end
        end

        result.get
      end
    end

    alias_method :detect, :find

    def find_index(value = nil, &block)
      if value.nil? && !block_given?
        return super
      end

      Sync do
        tasks = Concurrent::Array.new
        result_index = Concurrent::AtomicReference.new(nil)

        @enumerable.each_with_index do |item, index|
          break unless result_index.get.nil?

          task = Async do
            match = value.nil? ? block.call(item) : (item == value)
            if match
              # Use compare_and_set to ensure only the first match wins
              result_index.compare_and_set(nil, index)
            end
          end
          tasks << task
        end

        # Wait for all spawned tasks or until one is found
        tasks.each do |task|
          begin
            task.wait
          rescue Async::Stop
            # Task was stopped, that's ok
          end

          # If we found something, stop remaining tasks
          unless result_index.get.nil?
            tasks.each(&:stop)
            break
          end
        end

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
