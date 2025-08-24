# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::EarlyTerminable#find" do
  describe "#find" do
    it "returns first element matching condition" do
      result = [1, 2, 3, 4, 5].async.find { |n| n > 2 }
      expect(result).to eq(3)
    end

    it "returns nil when no element matches" do
      result = [1, 2, 3].async.find { |n| n > 10 }
      expect(result).to be_nil
    end

    it "returns nil for empty collection" do
      result = [].async.find { |n| n > 0 }
      expect(result).to be_nil
    end

    it "returns enumerator when no block given" do
      result = [1, 2, 3].async.find
      expect(result).to be_a(Enumerator)
    end

    it "uses ifnone proc when no match found" do
      ifnone = -> { "not found" }
      result = [1, 2, 3].async.find(ifnone) { |n| n > 10 }
      expect(result).to eq("not found")
    end

    it "doesn't call ifnone when match found" do
      called = false
      ifnone = -> {
        called = true
        "not found"
      }
      result = [1, 2, 3].async.find(ifnone) { |n| n > 1 }
      expect(result).to eq(2)
      expect(called).to be false
    end

    it "executes blocks in parallel" do
      execution_times = []
      start_time = Time.now

      result = [1, 2, 3, 4, 5].async.find do |n|
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

      result = (1..10).to_a.async.find do |n|
        checked << n
        # Simulate variable I/O delays - some tasks complete faster
        sleep(rand / 100.0)  # 0-10ms random delay
        completed << n

        n > 5  # Will match at 6
      end

      # With parallel execution, we'll get a matching element but not necessarily the first
      expect(result).to be > 5  # Will be some element > 5
      expect(result).to be <= 10  # But within valid range
      # Due to parallel execution, all tasks start but not all should complete
      expect(checked.size).to eq(10)  # All tasks start
      expect(completed.size).to be < 10  # But not all complete due to early termination
    end

    it "returns the first matching element by position" do
      # Even with parallel execution, should return first positional match
      results = []
      100.times do
        result = [1, 2, 3, 4, 5].async.find { |n| n > 2 }
        results << result
      end

      # Should always return 3 (first element > 2)
      expect(results.uniq).to eq([3])
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.find do |n|
          raise "Error on #{n}" if n == 2
          n > 10
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end

    it "works with complex objects" do
      users = [
        {name: "Alice", age: 25},
        {name: "Bob", age: 30},
        {name: "Charlie", age: 35}
      ]

      result = users.async.find { |u| u[:age] > 28 }
      expect(result).to eq({name: "Bob", age: 30})
    end
  end

  describe "#detect" do
    it "is an alias for find" do
      result = [1, 2, 3, 4, 5].async.detect { |n| n > 2 }
      expect(result).to eq(3)
    end
  end
end
