# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AsyncEnumerable::EarlyTerminable#one?" do
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
      checked = []
      completed = []

      result = (1..10).to_a.async.one? do |n|
        checked << n
        # Simulate variable I/O delays - some tasks complete faster
        sleep(rand / 100.0)  # 0-10ms random delay
        completed << n

        n > 5  # Will match 6, 7, 8, 9, 10 - should stop after second match
      end

      expect(result).to be false
      # Due to parallel execution, all tasks start but not all should complete
      expect(checked.size).to eq(10)  # All tasks start
      expect(completed.size).to be < 10  # But not all complete due to early termination
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
