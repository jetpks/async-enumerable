# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AsyncEnumerable::EarlyTerminable#take_while" do
  describe "#take_while" do
    it "returns elements while condition is true" do
      result = [1, 2, 3, 4, 5].async.take_while { |n| n < 4 }
      expect(result).to eq([1, 2, 3])
    end

    it "returns empty array when first element doesn't match" do
      result = [1, 2, 3].async.take_while { |n| n > 10 }
      expect(result).to eq([])
    end

    it "returns all elements when all match" do
      result = [1, 2, 3].async.take_while { |n| n < 10 }
      expect(result).to eq([1, 2, 3])
    end

    it "returns empty array for empty collection" do
      result = [].async.take_while { |n| n < 10 }
      expect(result).to eq([])
    end

    it "returns enumerator when no block given" do
      result = [1, 2, 3].async.take_while
      expect(result).to be_a(Enumerator)
    end

    it "stops at first false condition" do
      result = [2, 4, 6, 7, 8, 10].async.take_while { |n| n.even? }
      expect(result).to eq([2, 4, 6])
    end

    it "executes sequentially (not in parallel)" do
      execution_order = []

      result = [1, 2, 3, 4, 5].async.take_while do |n|
        execution_order << n
        n < 4  # Will take 1, 2, 3
      end

      expect(result).to eq([1, 2, 3])
      # Since take_while must be sequential, elements are checked in order
      expect(execution_order).to eq([1, 2, 3, 4])  # Checks up to first false
    end

    it "terminates at first false condition" do
      checked = []

      result = (1..10).to_a.async.take_while do |n|
        checked << n
        n < 4  # Will stop at 4
      end

      expect(result).to eq([1, 2, 3])
      # Sequential execution stops at first false
      expect(checked).to eq([1, 2, 3, 4])
    end

    it "maintains order of taken elements" do
      # Test many times to ensure ordering is consistent
      100.times do
        result = (1..10).to_a.async.take_while { |n| n <= 5 }
        expect(result).to eq([1, 2, 3, 4, 5])
      end
    end

    it "handles exceptions in async blocks" do
      expect do
        [1, 2, 3, 4, 5].async.take_while do |n|
          raise "Error on #{n}" if n == 3
          n < 10
        end
      end.to raise_error(RuntimeError, /Error on 3/)
    end

    it "works with strings" do
      words = ["apple", "apricot", "banana", "berry"]
      result = words.async.take_while { |w| w.start_with?("a") }
      expect(result).to eq(["apple", "apricot"])
    end

    it "works with nil values" do
      result = [1, 2, nil, 3].async.take_while { |n| n }
      expect(result).to eq([1, 2])
    end

    it "works with complex conditions" do
      result = [1, 3, 5, 7, 8, 9].async.take_while { |n| n.odd? }
      expect(result).to eq([1, 3, 5, 7])
    end

    it "works with hash" do
      hash = {a: 1, b: 2, c: 3, d: 4}
      result = hash.async.take_while { |k, v| v < 3 }
      expect(result).to eq([[:a, 1], [:b, 2]])
    end

    it "returns array even for non-array enumerables" do
      range_result = (1..10).async.take_while { |n| n < 5 }
      expect(range_result).to be_a(Array)
      expect(range_result).to eq([1, 2, 3, 4])
    end

    it "works with single element matching" do
      result = [1, 2, 3].async.take_while { |n| n == 1 }
      expect(result).to eq([1])
    end

    it "delegates to the wrapped enumerable" do
      # Since take_while must be sequential, we just delegate to @enumerable
      enumerable = (1..10).to_a
      async_enum = enumerable.async

      result = async_enum.take_while { |n| n < 5 }
      expected = enumerable.take_while { |n| n < 5 }

      expect(result).to eq(expected)
      expect(result).to eq([1, 2, 3, 4])
    end
  end
end
