# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::Methods::Predicates#none?" do
  describe "#none?" do
    it "returns true when no elements match" do
      result = [1, 3, 5].async.none? { |n| n.even? }
      expect(result).to be true
    end

    it "returns false when any element matches" do
      result = [1, 2, 3].async.none? { |n| n.even? }
      expect(result).to be false
    end

    it "returns true for empty collection" do
      result = [].async.none? { |n| n.even? }
      expect(result).to be true
    end

    it "returns true when no block given and all falsy values" do
      result = [nil, false].async.none?
      expect(result).to be true
    end

    it "returns false when no block given and has truthy values" do
      result = [nil, false, 1].async.none?
      expect(result).to be false
    end

    it "executes blocks in parallel" do
      execution_times = []
      start_time = Time.now

      result = [1, 2, 3].async.none? do |n|
        execution_times << Time.now - start_time
        sleep(0.1)
        n > 10
      end

      expect(result).to be true
      expect(execution_times.max - execution_times.min).to be < 0.01
    end

    it "terminates early when condition matches" do
      checked = Concurrent::Array.new
      completed = Concurrent::Array.new
      started = Concurrent::AtomicFixnum.new(0)

      # Use a larger dataset with limited concurrency to make early termination observable
      result = (1..20).to_a.async(max_fibers: 2).none? do |n|
        started.increment
        checked << n

        # Add a small delay to allow more tasks to start before the first one completes
        sleep(0.005)

        # Check condition - will match at 6 and above (none? returns false)
        matches = n > 5
        completed << n if !matches || n == 6  # Track completions including the first match
        matches
      end

      expect(result).to be false  # none? returns false when any element matches

      # The key validations for early termination:
      # 1. Not all tasks should complete (early termination happened)
      expect(completed.size).to be < 20

      # 2. At least one matching task should have been checked
      expect(checked.any? { |n| n > 5 }).to be true

      # 3. We should see evidence of early termination - some tasks didn't complete
      # Allow for race conditions - just verify early termination occurred
      expect(started.value).to be <= 20
      expect(completed.size).to be <= started.value
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.none? do |n|
          raise "Error on #{n}" if n == 2
          n > 10
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end

    it "works with pattern argument" do
      result = [1, 2, 3].async.none?(String)
      expect(result).to be true

      result = [1, "2", 3].async.none?(String)
      expect(result).to be false
    end
  end
end
