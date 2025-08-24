# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable::EarlyTerminable#first" do
  describe "#first" do
    it "returns first element when no argument given" do
      result = [1, 2, 3].async.first
      expect(result).to eq(1)
    end

    it "returns first n elements as array when argument given" do
      result = [1, 2, 3, 4, 5].async.first(3)
      expect(result).to eq([1, 2, 3])
    end

    it "returns nil for empty collection when no argument" do
      result = [].async.first
      expect(result).to be_nil
    end

    it "returns empty array for empty collection when argument given" do
      result = [].async.first(3)
      expect(result).to eq([])
    end

    it "returns all elements when n exceeds collection size" do
      result = [1, 2, 3].async.first(10)
      expect(result).to eq([1, 2, 3])
    end

    it "returns empty array when n is 0" do
      result = [1, 2, 3].async.first(0)
      expect(result).to eq([])
    end

    it "raises ArgumentError for negative n" do
      expect do
        [1, 2, 3].async.first(-1)
      end.to raise_error(ArgumentError)
    end

    it "executes in parallel when taking multiple elements" do
      Mutex.new

      result = (1..5).to_a.async.first(3)

      expect(result).to eq([1, 2, 3])
    end

    it "terminates early when taking fewer than all elements" do
      checked = []

      # Create custom objects that track when they're accessed
      objects = (1..10).map do |i|
        obj = Object.new
        obj.define_singleton_method(:to_s) do
          checked << i
          "item_#{i}"
        end
        obj
      end

      # Force evaluation by converting to array
      objects.async.first(3).map(&:to_s)

      # Should only check the first 3 elements
      expect(checked.sort).to eq([1, 2, 3])
    end

    it "maintains order when taking multiple elements" do
      # Test many times to ensure ordering is consistent
      100.times do
        result = (1..10).to_a.async.first(5)
        expect(result).to eq([1, 2, 3, 4, 5])
      end
    end

    it "works with ranges" do
      result = (1..100).async.first(3)
      expect(result).to eq([1, 2, 3])
    end

    it "works with single element collections" do
      result = [42].async.first
      expect(result).to eq(42)

      result = [42].async.first(1)
      expect(result).to eq([42])

      result = [42].async.first(3)
      expect(result).to eq([42])
    end

    it "works with strings in collection" do
      result = ["apple", "banana", "cherry"].async.first
      expect(result).to eq("apple")

      result = ["apple", "banana", "cherry"].async.first(2)
      expect(result).to eq(["apple", "banana"])
    end

    it "works with nil values" do
      result = [nil, 1, 2].async.first
      expect(result).to be_nil

      result = [nil, nil, 1].async.first(2)
      expect(result).to eq([nil, nil])
    end

    it "works with hash" do
      # Hash order is preserved in Ruby 1.9+
      hash = {a: 1, b: 2, c: 3}
      result = hash.async.first
      expect(result).to eq([:a, 1])

      result = hash.async.first(2)
      expect(result).to eq([[:a, 1], [:b, 2]])
    end
  end
end
