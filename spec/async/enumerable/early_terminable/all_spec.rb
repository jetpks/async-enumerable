# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::EarlyTerminable#all?" do
  describe "#all?" do
    it "returns true when all elements match" do
      result = [2, 4, 6].async.all? { |n| n.even? }
      expect(result).to be true
    end

    it "returns false when any element doesn't match" do
      result = [1, 2, 3].async.all? { |n| n.even? }
      expect(result).to be false
    end

    it "returns true for empty collection" do
      result = [].async.all? { |n| n.even? }
      expect(result).to be true
    end

    it "returns true when no block given and no falsy values" do
      result = [1, true, "hello"].async.all?
      expect(result).to be true
    end

    it "returns false when no block given and has falsy values" do
      result = [1, nil, "hello"].async.all?
      expect(result).to be false
    end

    it "executes blocks in parallel" do
      execution_times = []
      start_time = Time.now

      result = [1, 2, 3].async.all? do |n|
        execution_times << Time.now - start_time
        sleep(0.1)
        n > 0
      end

      expect(result).to be true
      expect(execution_times.max - execution_times.min).to be < 0.01
    end

    it "terminates early when condition fails" do
      checked = []
      completed = []

      result = (1..10).to_a.async.all? do |n|
        checked << n
        # Simulate variable I/O delays - some tasks complete faster
        sleep(rand / 100.0)  # 0-10ms random delay
        completed << n
        n < 5  # Will fail at 5 and above
      end

      expect(result).to be false
      # Due to parallel execution, all tasks start but not all should complete
      expect(checked.size).to eq(10)  # All tasks start
      expect(completed.size).to be < 10  # But not all complete due to early termination
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.all? do |n|
          raise "Error on #{n}" if n == 2
          n > 0
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end

    it "works with pattern argument" do
      result = [2, 4, 6].async.all?(Integer)
      expect(result).to be true

      result = [2, "4", 6].async.all?(Integer)
      expect(result).to be false
    end
  end
end
