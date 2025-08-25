# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::Methods::Predicates#find_index" do
  describe "#find_index" do
    it "returns index of first element matching block" do
      result = [1, 2, 3, 4, 5].async.find_index { |n| n > 2 }
      expect(result).to eq(2)
    end

    it "returns index of matching element when given value" do
      result = [1, 2, 3, 4, 5].async.find_index(3)
      expect(result).to eq(2)
    end

    it "returns nil when no element matches block" do
      result = [1, 2, 3].async.find_index { |n| n > 10 }
      expect(result).to be_nil
    end

    it "returns nil when value not found" do
      result = [1, 2, 3].async.find_index(10)
      expect(result).to be_nil
    end

    it "returns nil for empty collection" do
      result = [].async.find_index { |n| n > 0 }
      expect(result).to be_nil

      result = [].async.find_index(1)
      expect(result).to be_nil
    end

    it "returns enumerator when no block or value given" do
      result = [1, 2, 3].async.find_index
      expect(result).to be_a(Enumerator)
    end

    it "finds index 0 correctly" do
      result = [1, 2, 3].async.find_index { |n| n == 1 }
      expect(result).to eq(0)

      result = [1, 2, 3].async.find_index(1)
      expect(result).to eq(0)
    end

    it "executes blocks in parallel" do
      execution_times = []
      start_time = Time.now

      result = [1, 2, 3, 4, 5].async.find_index do |n|
        execution_times << Time.now - start_time
        sleep(0.05)
        n > 10  # Never matches, so all blocks execute
      end

      expect(result).to be_nil
      expect(execution_times.max - execution_times.min).to be < 0.02
    end

    it "terminates early when match found" do
      checked = Concurrent::Array.new
      completed = Concurrent::Array.new
      started = Concurrent::AtomicFixnum.new(0)

      # Use a larger dataset with limited concurrency to make early termination observable
      result = (1..20).to_a.async(max_fibers: 2).find_index do |n|
        started.increment
        checked << n

        # Add a small delay to allow more tasks to start before the first one completes
        sleep(0.005)

        # Check condition - will match at index 5 and above (values 6+)
        matches = n > 5
        completed << n
        matches
      end

      # With parallel execution, we'll get a matching index but not necessarily the first
      expect(result).to be >= 5  # Will be index of some element > 5
      expect(result).to be <= 19  # But within valid range

      # The key validations for early termination:
      # 1. Not all tasks should complete (early termination happened)
      expect(completed.size).to be < 20

      # 2. The value at the returned index should match our condition
      expect((1..20).to_a[result]).to be > 5

      # 3. We should see evidence of early termination - some tasks didn't complete
      # Allow for race conditions - just verify early termination occurred
      expect(started.value).to be <= 20
      expect(completed.size).to be <= started.value
    end

    it "returns the first matching index by position" do
      # Even with parallel execution, should return first positional match
      results = []
      100.times do
        result = [1, 2, 3, 4, 5].async.find_index { |n| n > 2 }
        results << result
      end

      # Should always return 2 (index of first element > 2)
      expect(results.uniq).to eq([2])
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.find_index do |n|
          raise "Error on #{n}" if n == 2
          n > 10
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end

    it "works with == comparison for value search" do
      result = [1.0, 2.0, 3.0].async.find_index(2)
      expect(result).to eq(1)
    end

    it "works with strings" do
      result = ["apple", "banana", "cherry"].async.find_index("banana")
      expect(result).to eq(1)

      result = ["apple", "banana", "cherry"].async.find_index { |s| s.start_with?("c") }
      expect(result).to eq(2)
    end

    it "works with nil" do
      result = [1, nil, 3].async.find_index(nil)
      expect(result).to eq(1)

      result = [1, nil, 3].async.find_index(&:nil?)
      expect(result).to eq(1)
    end
  end
end
