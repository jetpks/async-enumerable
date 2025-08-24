# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AsyncEnumerable::EarlyTerminable#include?" do
  describe "#include?" do
    it "returns true when element exists" do
      result = [1, 2, 3].async.include?(2)
      expect(result).to be true
    end

    it "returns false when element doesn't exist" do
      result = [1, 2, 3].async.include?(5)
      expect(result).to be false
    end

    it "returns false for empty collection" do
      result = [].async.include?(1)
      expect(result).to be false
    end

    it "uses == for comparison" do
      result = [1.0, 2.0, 3.0].async.include?(2)
      expect(result).to be true
    end

    it "executes checks in parallel" do
      large_array = (1..100).to_a
      start_time = Time.now

      # Create a custom class that tracks when equality is checked
      checked_times = []
      target = Object.new
      target.define_singleton_method(:==) do |other|
        checked_times << Time.now - start_time if other.is_a?(Integer)
        false  # Never matches, so we check everything
      end

      result = large_array.async.include?(target)

      expect(result).to be false
      # Should have checked all elements
      expect(checked_times.size).to eq(100)
      # Checks should happen roughly simultaneously
      if checked_times.any?
        expect(checked_times.max - checked_times.min).to be < 0.1
      end
    end

    it "terminates early when element found" do
      checked = []

      # Create custom objects that track equality checks
      objects = (1..5).map do |i|
        obj = Object.new
        obj.define_singleton_method(:==) do |other|
          checked << i if other == :target
          i == 3  # Match on element 3
        end
        obj
      end

      result = objects.async.include?(:target)

      expect(result).to be true
      # Due to parallel execution, might check a few more than needed
      # but should not check all 5
      expect(checked.size).to be <= 4
    end

    it "handles exceptions during comparison" do
      bad_obj = Object.new
      bad_obj.define_singleton_method(:==) do |other|
        raise "Comparison error"
      end

      expect do
        [1, bad_obj, 3].async.include?(2)
      end.to raise_error(RuntimeError, /Comparison error/)
    end

    it "works with strings" do
      result = ["apple", "banana", "cherry"].async.include?("banana")
      expect(result).to be true
    end

    it "works with symbols" do
      result = [:one, :two, :three].async.include?(:two)
      expect(result).to be true
    end

    it "works with nil" do
      result = [1, nil, 3].async.include?(nil)
      expect(result).to be true
    end
  end

  describe "#member?" do
    it "is an alias for include?" do
      result = [1, 2, 3].async.member?(2)
      expect(result).to be true
    end
  end
end
