# frozen_string_literal: true

require "spec_helper"
require "async/clock"

RSpec.describe Async::Enumerator do
  describe "#async" do
    it "returns an Async::Enumerator instance" do
      result = [1, 2, 3].async
      expect(result).to be_a(Async::Enumerator)
    end

    it "is idempotent - calling async multiple times returns the same instance" do
      first = [1, 2, 3].async
      second = first.async
      third = second.async

      expect(second).to be(first)  # Same object identity
      expect(third).to be(first)   # Same object identity
      expect(third).to be(second)  # Same object identity
    end

    it "allows chaining async calls without creating new instances" do
      result = [1, 2, 3].async.async.async.map { |x| x * 2 }
      expect(result.to_a).to eq([2, 4, 6])
    end
  end

  describe "#each" do
    it "executes block for each element" do
      results = []
      [1, 2, 3].async.each { |x| results << x * 2 }
      expect(results.sort).to eq([2, 4, 6])
    end

    it "returns self for chaining" do
      result = [1, 2, 3].async.each { |x| x * 2 }
      expect(result).to be_a(Async::Enumerator)
    end

    it "returns enumerator when no block given" do
      result = [1, 2, 3].async.each
      expect(result).to be_a(Enumerator)
    end

    it "executes blocks in parallel" do
      start_time = Async::Clock.now
      sleep_duration = 0.1
      execution_times = []

      [1, 2, 3].async.each do |x|
        execution_times << Async::Clock.now - start_time
        sleep(sleep_duration)
      end

      # All blocks should start roughly at the same time (within 10ms)
      expect(execution_times.max - execution_times.min).to be < 0.01

      elapsed_time = Async::Clock.now - start_time
      # Total time should be close to one sleep duration, not three
      expect(elapsed_time).to be < (sleep_duration * 2)
      expect(elapsed_time).to be >= sleep_duration
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3].async.each do |x|
          raise "Error on #{x}" if x == 2
        end
      end.to raise_error(RuntimeError, /Error on 2/)
    end

    it "maintains access to element values" do
      results = {}
      [:a, :b, :c].async.each do |sym|
        results[sym] = sym.to_s.upcase
      end
      expect(results).to eq({a: "A", b: "B", c: "C"})
    end

    it "works with custom enumerable classes" do
      simple_list_class = Class.new do
        include Enumerable
        def initialize(items)
          @items = items
        end

        def each(&block)
          @items.each(&block)
        end
      end

      results = []
      simple_list_class.new([1, 2, 3]).async.each { |x| results << x }
      expect(results.sort).to eq([1, 2, 3])
    end

    it "allows chaining with other async methods" do
      results = []
      chain_result = [1, 2, 3].async
        .each { |x| results << x }
        .map { |x| x * 2 }

      expect(results.sort).to eq([1, 2, 3])
      expect(chain_result).to be_a(Async::Enumerator)
      expect(chain_result.sync).to eq([2, 4, 6])
    end

    it "handles empty collections" do
      results = []
      [].async.each { |x| results << x }
      expect(results).to eq([])
    end
  end

  # These tests validate behavior specific to map that isn't covered
  # by the generic Enumerable tests or the each tests
  describe "#map" do
    it "returns an Async::Enumerator for chaining" do
      require "set"
      result = Set[1, 2, 3].async.map { |x| x * 2 }
      expect(result).to be_a(Async::Enumerator)
      expect(result.sort).to eq([2, 4, 6])
    end

    it "allows chaining multiple async operations" do
      result = [1, 2, 3, 4, 5].async
        .map { |x| x * 2 }
        .select { |x| x > 4 }
        .map { |x| x + 1 }
      expect(result).to be_a(Async::Enumerator)
      expect(result).to eq([7, 9, 11])
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

  describe "#sync" do
    it "is an alias for to_a" do
      result = (1..3).async.sync
      expect(result).to eq([1, 2, 3])
    end

    it "provides a semantic way to get the wrapped enumerable" do
      async_enum = [1, 2, 3].async
      result = async_enum.sync
      expect(result).to eq([1, 2, 3])
    end

    it "is useful for getting the enumerable without transformation" do
      set = Set[1, 2, 3]
      result = set.async.sync
      expect(result).to be_a(Array)
      expect(result.sort).to eq([1, 2, 3])
    end

    it "works at the end of an async chain" do
      result = [:foo, :bar, :baz].async
        .map { |s| s.to_s }
        .select { |s| s.length == 3 }
        .map { |s| s.upcase }
        .sync
      expect(result).to eq(["FOO", "BAR", "BAZ"])
    end
  end

  describe "comparison" do
    it "equals arrays with same elements" do
      async_enum = [1, 2, 3].async
      expect(async_enum).to eq([1, 2, 3])
      expect(async_enum == [1, 2, 3]).to be true
    end

    it "does not equal arrays with different elements" do
      async_enum = [1, 2, 3].async
      expect(async_enum).not_to eq([1, 2, 4])
      expect(async_enum == [1, 2, 4]).to be false
    end

    it "compares correctly with <=>" do
      async_enum = [1, 2, 3].async
      expect(async_enum <=> [1, 2, 3]).to eq(0)
      expect(async_enum <=> [1, 2, 4]).to eq(-1)
      expect(async_enum <=> [1, 2, 2]).to eq(1)
    end

    it "works with chained operations" do
      result = [1, 2, 3].async.map { |x| x * 2 }
      expect(result).to eq([2, 4, 6])
    end

    it "allows Comparable methods" do
      async_enum = [1, 2, 3].async
      expect(async_enum).to be <= [1, 2, 4]
      expect(async_enum).to be >= [1, 2, 2]
    end
  end
end
