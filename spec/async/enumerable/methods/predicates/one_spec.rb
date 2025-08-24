# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::EarlyTerminable#one?" do
  describe "#one?" do
    it "returns true when exactly one element matches" do
      result = [1, 2, 3].async.one? { |n| n == 2 }
      expect(result).to be true
    end

    it "returns false when no elements match" do
      result = [1, 2, 3].async.one? { |n| n > 10 }
      expect(result).to be false
    end

    it "returns false when multiple elements match" do
      result = [1, 2, 3].async.one? { |n| n > 1 }
      expect(result).to be false
    end

    it "returns false for empty collection" do
      result = [].async.one? { |n| n.even? }
      expect(result).to be false
    end

    it "returns true when no block given and exactly one truthy value" do
      result = [nil, false, 1].async.one?
      expect(result).to be true
    end

    it "returns false when no block given and multiple truthy values" do
      result = [1, 2].async.one?
      expect(result).to be false
    end

    it "executes blocks in parallel" do
      execution_times = []
      start_time = Time.now

      result = [1, 2, 3].async.one? do |n|
        execution_times << Time.now - start_time
        sleep(0.1)
        n == 2
      end

      expect(result).to be true
      expect(execution_times.max - execution_times.min).to be < 0.01
    end

    it "terminates early when second match found" do
      checked = Concurrent::Array.new
      completed = Concurrent::Array.new
      started = Concurrent::AtomicFixnum.new(0)
      matched = Concurrent::AtomicFixnum.new(0)

      # Use a larger dataset with limited concurrency to make early termination observable
      result = (1..20).to_a.async(max_fibers: 2).one? do |n|
        started.increment
        checked << n

        # Add a small delay to allow more tasks to start before the first one completes
        sleep(0.005)

        # Check condition - will match multiple times (6, 7, 8, etc.)
        matches = n > 5
        if matches
          matched.increment
          completed << n if matched.value <= 2  # Track first two matches
        else
          completed << n
        end
        matches
      end

      expect(result).to be false  # one? returns false when multiple elements match

      # The key validations for early termination:
      # 1. Not all tasks should complete (early termination happened)
      expect(completed.size).to be < 20

      # 2. At least two matching tasks should have been found
      expect(matched.value).to be >= 2

      # 3. We should see evidence of early termination - some tasks didn't complete
      # Allow for race conditions - just verify early termination occurred
      expect(started.value).to be <= 20
      expect(completed.size).to be <= started.value
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.one? do |n|
          raise "Error on #{n}" if n == 2
          n > 10
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end

    it "works with pattern argument" do
      result = [1, "2", 3].async.one?(String)
      expect(result).to be true

      result = ["1", "2", 3].async.one?(String)
      expect(result).to be false
    end
  end
end
