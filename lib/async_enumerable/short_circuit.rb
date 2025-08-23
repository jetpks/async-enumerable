# frozen_string_literal: true

module AsyncEnumerable
  module ShortCircuit
    # Predicates that short-circuit

    def all?(&block)
      return super unless block_given?

      result = true
      continue = true

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)

        @enumerable.each do |item|
          break unless continue

          barrier.async do
            if continue && !block.call(item)
              result = false
              continue = false
            end
          end
        end

        barrier.wait
      end

      result
    end

    def any?(&block)
      return super unless block_given?

      result = false
      continue = true

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)

        @enumerable.each do |item|
          break unless continue

          barrier.async do
            if continue && block.call(item)
              result = true
              continue = false
            end
          end
        end

        barrier.wait
      end

      result
    end

    def none?(&block)
      !any?(&block)
    end

    def one?(&block)
      return super unless block_given?

      count = 0
      continue = true

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)
        mutex = Mutex.new

        @enumerable.each do |item|
          break unless continue

          barrier.async do
            if continue && block.call(item)
              mutex.synchronize do
                count += 1
                continue = false if count > 1
              end
            end
          end
        end

        barrier.wait
      end

      count == 1
    end

    def include?(obj)
      any? { |item| item == obj }
    end

    alias_method :member?, :include?

    # Find methods that short-circuit

    def find(&block)
      return super unless block_given?

      result = nil
      found = false

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)

        @enumerable.each_with_index do |item, index|
          break if found

          barrier.async do
            if !found && block.call(item)
              result = item
              found = true
            end
          end
        end

        barrier.wait
      end

      result
    end

    alias_method :detect, :find

    def find_index(value = nil, &block)
      if value.nil? && !block_given?
        return super
      end

      result = nil
      found = false

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)

        @enumerable.each_with_index do |item, index|
          break if found

          barrier.async do
            if !found
              match = value.nil? ? block.call(item) : (item == value)
              if match
                result = index
                found = true
              end
            end
          end
        end

        barrier.wait
      end

      result
    end

    # Take methods that short-circuit

    def first(n = nil)
      if n.nil?
        # Just get the first element
        @enumerable.first
      else
        # Get first n elements
        take(n)
      end
    end

    def take(n)
      return [] if n <= 0

      results = []
      mutex = Mutex.new

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)

        @enumerable.each_with_index do |item, index|
          break if index >= n

          barrier.async do
            mutex.synchronize do
              results[index] = item
            end
          end
        end

        barrier.wait
      end

      results.compact
    end

    def take_while(&block)
      return super unless block_given?

      # For take_while, we need sequential checking since each element
      # depends on previous ones not breaking the condition
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
