# frozen_string_literal: true

require "async/barrier"
require "async/semaphore"

module AsyncEnumerable
  module ShortCircuit
    # Predicates that short-circuit by stopping tasks early

    def all?(&block)
      return super unless block_given?

      Sync do
        tasks = []
        failed = false

        @enumerable.each do |item|
          break if failed

          task = Async do
            unless block.call(item)
              failed = true
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
          if failed
            tasks.each(&:stop)
            break
          end
        end

        !failed
      end
    end

    def any?(&block)
      return super unless block_given?

      Sync do
        tasks = []
        found = false

        @enumerable.each do |item|
          break if found

          task = Async do
            if block.call(item)
              found = true
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
          if found
            tasks.each(&:stop)
            break
          end
        end

        found
      end
    end

    def none?(&block)
      !any?(&block)
    end

    def one?(&block)
      return super unless block_given?

      Sync do
        tasks = []
        count = 0
        count_mutex = Mutex.new
        too_many = false

        @enumerable.each do |item|
          break if too_many

          task = Async do
            if block.call(item)
              count_mutex.synchronize do
                count += 1
                too_many = true if count > 1
              end
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
          if too_many
            tasks.each(&:stop)
            break
          end
        end

        count == 1
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
        tasks = []
        result = nil
        found = false

        @enumerable.each do |item|
          break if found

          task = Async do
            if block.call(item)
              result = item
              found = true
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
          if found
            tasks.each(&:stop)
            break
          end
        end

        result
      end
    end

    alias_method :detect, :find

    def find_index(value = nil, &block)
      if value.nil? && !block_given?
        return super
      end

      Sync do
        tasks = []
        result_index = nil
        found = false

        @enumerable.each_with_index do |item, index|
          break if found

          task = Async do
            match = value.nil? ? block.call(item) : (item == value)
            if match
              result_index = index
              found = true
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
          if found
            tasks.each(&:stop)
            break
          end
        end

        result_index
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
        results = []
        mutex = Mutex.new

        @enumerable.each_with_index do |item, index|
          break if index >= n

          barrier.async do
            mutex.synchronize do
              results[index] = item
            end
          end
        end

        # Wait for all spawned tasks
        barrier.wait

        results
      end
    end

    def take_while(&block)
      return super unless block_given?

      # take_while needs sequential checking, so we can't parallelize
      # Keep the synchronous implementation
      results = []

      @enumerable.each do |item|
        break unless block.call(item)
        results << item
      end

      results
    end

    # Override lazy to return a non-async lazy enumerator
    # since lazy uses breaks internally which don't work with async
    def lazy
      @enumerable.lazy
    end
  end
end
