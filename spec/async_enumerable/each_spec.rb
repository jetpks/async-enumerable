# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AsyncEnumerable::Each" do
  describe "#each" do
    it "executes block for each element" do
      results = []
      [1, 2, 3].async.each { |x| results << x * 2 }
      expect(results.sort).to eq([2, 4, 6])
    end

    it "returns self for chaining" do
      result = [1, 2, 3].async.each { |x| x * 2 }
      expect(result).to be_a(AsyncEnumerable::Async)
    end

    it "returns enumerator when no block given" do
      result = [1, 2, 3].async.each
      expect(result).to be_a(Enumerator)
    end

    it "executes blocks in parallel" do
      start_time = Time.now
      sleep_duration = 0.1
      execution_times = []

      [1, 2, 3].async.each do |x|
        execution_times << Time.now - start_time
        sleep(sleep_duration)
      end

      # All blocks should start roughly at the same time (within 10ms)
      expect(execution_times.max - execution_times.min).to be < 0.01

      elapsed_time = Time.now - start_time
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
      [1, 2, 3].async
        .each { |x| results << x }
        .map { |x| x * 2 }

      expect(results.sort).to eq([1, 2, 3])
    end

    it "handles empty collections" do
      results = []
      [].async.each { |x| results << x }
      expect(results).to eq([])
    end
  end
end
