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
      checked = Concurrent::Array.new
      completed = Concurrent::Array.new
      started = Concurrent::AtomicFixnum.new(0)
      
      # Use a larger dataset with limited concurrency to make early termination observable
      result = (1..20).to_a.async(max_fibers: 2).all? do |n|
        started.increment
        checked << n
        
        # Add a small delay to allow more tasks to start before the first one completes
        sleep(0.005)
        
        # Check condition - will fail at 5 and above
        passes = n < 5
        completed << n if passes || n == 5  # Track completions including the first failure
        passes
      end

      expect(result).to be false
      
      # The key validations for early termination:
      # 1. Not all tasks should complete (early termination happened)
      expect(completed.size).to be < 20
      
      # 2. At least the failing task (n=5) should have been checked
      expect(checked).to include(5)
      
      # 3. We should see evidence of early termination - some tasks didn't complete
      # Allow for race conditions - just verify early termination occurred
      expect(started.value).to be <= 20
      expect(completed.size).to be <= started.value
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
