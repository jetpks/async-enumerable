# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AsyncEnumerable::EarlyTerminable#take" do
  describe "#take" do
    it "returns first n elements as array" do
      result = [1, 2, 3, 4, 5].async.take(3)
      expect(result).to eq([1, 2, 3])
    end

    it "returns all elements when n exceeds collection size" do
      result = [1, 2, 3].async.take(10)
      expect(result).to eq([1, 2, 3])
    end

    it "returns empty array when n is 0" do
      result = [1, 2, 3].async.take(0)
      expect(result).to eq([])
    end

    it "returns empty array for empty collection" do
      result = [].async.take(3)
      expect(result).to eq([])
    end

    it "raises ArgumentError for negative n" do
      expect do
        [1, 2, 3].async.take(-1)
      end.to raise_error(ArgumentError)
    end

    it "terminates early when taking fewer than all elements" do
      checked = []

      # Create custom objects that track when they're accessed
      objects = (1..10).map do |i|
        obj = Object.new
        obj.define_singleton_method(:inspect) do
          checked << i
          "item_#{i}"
        end
        obj
      end

      # Force evaluation
      objects.async.take(3).map(&:inspect)

      # Should only check the first 3 elements
      expect(checked.sort).to eq([1, 2, 3])
    end

    it "maintains order of elements" do
      # Test many times to ensure ordering is consistent
      100.times do
        result = (1..10).to_a.async.take(5)
        expect(result).to eq([1, 2, 3, 4, 5])
      end
    end

    it "works with ranges" do
      result = (1..100).async.take(5)
      expect(result).to eq([1, 2, 3, 4, 5])
    end

    it "works with infinite sequences (lazy evaluation)" do
      infinite = (1..Float::INFINITY).lazy
      result = infinite.async.take(3)
      expect(result).to eq([1, 2, 3])
    end

    it "works with single element collections" do
      result = [42].async.take(1)
      expect(result).to eq([42])

      result = [42].async.take(3)
      expect(result).to eq([42])
    end

    it "works with strings in collection" do
      result = ["apple", "banana", "cherry", "date"].async.take(2)
      expect(result).to eq(["apple", "banana"])
    end

    it "works with nil values" do
      result = [nil, nil, 1, 2].async.take(3)
      expect(result).to eq([nil, nil, 1])
    end

    it "works with hash" do
      # Hash order is preserved in Ruby 1.9+
      hash = {a: 1, b: 2, c: 3, d: 4}
      result = hash.async.take(2)
      expect(result).to eq([[:a, 1], [:b, 2]])
    end

    it "works with sets" do
      require "set"
      set = Set[1, 2, 3, 4, 5]
      result = set.async.take(3)
      expect(result.size).to eq(3)
      expect(result.all? { |n| set.include?(n) }).to be true
    end

    it "returns array even for non-array enumerables" do
      range_result = (1..5).async.take(3)
      expect(range_result).to be_a(Array)
      expect(range_result).to eq([1, 2, 3])

      hash_result = {a: 1, b: 2}.async.take(1)
      expect(hash_result).to be_a(Array)
      expect(hash_result).to eq([[:a, 1]])
    end
  end
end
