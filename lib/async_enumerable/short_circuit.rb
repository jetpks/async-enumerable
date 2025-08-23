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

    # TODO: i'm not sure we need the `too_many` variable in `#one?` -- it seems
    # like we could just check `count > 1` instead of tracking state
    # separately
    def one?(&block)
      return super unless block_given?

      Sync do
        tasks = Concurrent::Array.new
        count = Concurrent::AtomicFixnum.new(0)
        too_many = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if too_many.true?

          task = Async do
            if block.call(item)
              new_count = count.increment
              too_many.make_true if new_count > 1
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
          if too_many.true?
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

    # TODO: i'm not sure we need the `found` variable in `#find` -- it seems
    # like we could just check `result.nil?` instead of tracking state
    # separately
    def find(&block)
      return super unless block_given?

      Sync do
        tasks = Concurrent::Array.new
        result = Concurrent::AtomicReference.new(nil)
        found = Concurrent::AtomicBoolean.new(false)

        @enumerable.each do |item|
          break if found.true?

          task = Async do
            if block.call(item)
              result.set(item)
              found.make_true
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
          if found.true?
            tasks.each(&:stop)
            break
          end
        end

        result.get
      end
    end

    alias_method :detect, :find

    # TODO: i'm not sure we need the `found` variable in `#find_index` -- it
    # seems like we could just check `result_index.nil?` instead of tracking
    # state separately
    def find_index(value = nil, &block)
      if value.nil? && !block_given?
        return super
      end

      Sync do
        tasks = Concurrent::Array.new
        result_index = Concurrent::AtomicReference.new(nil)
        found = Concurrent::AtomicBoolean.new(false)

        @enumerable.each_with_index do |item, index|
          break if found.true?

          task = Async do
            match = value.nil? ? block.call(item) : (item == value)
            if match
              result_index.set(index)
              found.make_true
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
          if found.true?
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

    # TODO: since we can't do this asynchronously, just defer back to the
    # synchronous version rather than reimplementing synchronously
    def take_while(&block)
      return super unless block_given?

      # take_while needs sequential checking, so we can't parallelize
      # Keep the synchronous implementation
      results = Concurrent::Array.new

      @enumerable.each do |item|
        break unless block.call(item)
        results << item
      end

      results.to_a
    end

    # Override lazy to return a non-async lazy enumerator
    # since lazy uses breaks internally which don't work with async
    def lazy
      @enumerable.lazy
    end
  end
end
