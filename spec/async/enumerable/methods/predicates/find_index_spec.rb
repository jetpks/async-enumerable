# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::EarlyTerminable#find_index" do
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
      checked = []
      completed = []

      result = (1..10).to_a.async.find_index do |n|
        checked << n
        # Simulate variable I/O delays - some tasks complete faster
        sleep(rand / 100.0)  # 0-10ms random delay
        completed << n

        n > 5  # Will match at index 5 (value 6)
      end

      # With parallel execution, we'll get a matching index but not necessarily the first
      expect(result).to be >= 5  # Will be index of some element > 5
      expect(result).to be <= 9  # But within valid range
      # Due to parallel execution, all tasks start but not all should complete
      expect(checked.size).to eq(10)  # All tasks start
      expect(completed.size).to be < 10  # But not all complete due to early termination
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
