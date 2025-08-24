# frozen_string_literal: true

require "spec_helper"

RSpec.describe AsyncEnumerable::AsyncEnumerator do
  describe "#async" do
    it "returns an AsyncEnumerable::Async instance" do
      result = [1, 2, 3].async
      expect(result).to be_a(AsyncEnumerable::AsyncEnumerator)
    end
  end

  # TODO: this is here because we originally implemented `map` separately from
  # `each`, but now we just use Enumerable.map which uses our asynchronous
  # `each` -- let's make sure these test cases are adequately covered by other
  # tests in the suite and if so, let's remove them
  describe "#map" do
    it "applies block to all elements" do
      result = [1, 2, 3].async.map { |x| x * 2 }
      expect(result).to eq([2, 4, 6])
    end

    it "maintains order despite async execution" do
      result = [1, 2, 3, 4, 5].async.map { |x| x * 2 }
      expect(result).to eq([2, 4, 6, 8, 10])
    end

    it "returns an array for array input" do
      result = [1, 2, 3].async.map { |x| x * 2 }
      expect(result).to be_a(Array)
    end

    it "returns an array for set input" do
      require "set"
      result = Set[1, 2, 3].async.map { |x| x * 2 }
      expect(result).to be_a(Array)
      expect(result.sort).to eq([2, 4, 6])
    end

    it "executes blocks in parallel" do
      start_time = Time.now
      sleep_duration = 0.1

      result = [1, 2, 3].async.map do |x|
        sleep(sleep_duration)
        x * 2
      end

      elapsed_time = Time.now - start_time

      expect(result).to eq([2, 4, 6])
      expect(elapsed_time).to be < (sleep_duration * 3)
      expect(elapsed_time).to be >= sleep_duration
    end

    it "returns enumerator when no block given" do
      result = [1, 2, 3].async.map
      expect(result).to be_a(Enumerator)
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.map do |x|
          raise "Error on #{x}" if x == 2
          x * 2
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end
  end

  describe "#to_a" do
    it "converts to array" do
      result = (1..3).async.to_a
      expect(result).to eq([1, 2, 3])
    end
  end
end
