# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::EarlyTerminable#any?" do
  describe "#any?" do
    it "returns true when any element matches" do
      result = [1, 2, 3].async.any? { |n| n.even? }
      expect(result).to be true
    end

    it "returns false when no elements match" do
      result = [1, 3, 5].async.any? { |n| n.even? }
      expect(result).to be false
    end

    it "returns false for empty collection" do
      result = [].async.any? { |n| n.even? }
      expect(result).to be false
    end

    it "returns true when no block given and has truthy values" do
      result = [nil, false, 1].async.any?
      expect(result).to be true
    end

    it "returns false when no block given and all falsy values" do
      result = [nil, false].async.any?
      expect(result).to be false
    end

    it "executes blocks in parallel" do
      execution_times = []
      start_time = Time.now

      result = [1, 2, 3].async.any? do |n|
        execution_times << Time.now - start_time
        sleep(0.1)
        n > 10
      end

      expect(result).to be false
      expect(execution_times.max - execution_times.min).to be < 0.01
    end

    it "terminates early when condition matches" do
      checked = []
      completed = []

      result = (1..10).to_a.async.any? do |n|
        checked << n
        # Simulate variable I/O delays - some tasks complete faster
        sleep(rand / 100.0)  # 0-10ms random delay
        completed << n
        n > 5  # Will succeed at 6 and above
      end

      expect(result).to be true
      # Due to parallel execution, all tasks start but not all should complete
      expect(checked.size).to eq(10)  # All tasks start
      expect(completed.size).to be < 10  # But not all complete due to early termination
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.any? do |n|
          raise "Error on #{n}" if n == 2
          n > 10
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end

    it "works with pattern argument" do
      result = [1, "2", 3].async.any?(String)
      expect(result).to be true

      result = [1, 2, 3].async.any?(String)
      expect(result).to be false
    end
  end
end
