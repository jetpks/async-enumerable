# frozen_string_literal: true

require "spec_helper"

# Custom enumerable class for testing
class CustomList
  include Enumerable

  def initialize(items = [])
    @items = items.is_a?(Array) ? items : [items].flatten
  end

  def each(&block)
    return enum_for(:each) unless block_given?
    @items.each(&block)
  end

  def ==(other)
    other.is_a?(self.class) && @items == other.instance_variable_get(:@items)
  end
end

# Another custom enumerable that only accepts items one by one
class StrictList
  include Enumerable

  def initialize
    @items = []
  end

  def <<(item)
    @items << item
    self
  end

  def each(&block)
    return enum_for(:each) unless block_given?
    @items.each(&block)
  end

  def replace(array)
    @items = array
    self
  end
end

RSpec.describe "AsyncEnumerable with custom classes" do
  describe "CustomList (accepts array in constructor)" do
    it "returns an async wrapper" do
      list = CustomList.new([1, 2, 3])
      result = list.async
      expect(result).to be_a(AsyncEnumerable::Async)
    end

    it "preserves the original class after map" do
      list = CustomList.new([1, 2, 3])
      result = list.async.map { |x| x * 2 }
      expect(result).to be_a(CustomList)
      expect(result).to eq(CustomList.new([2, 4, 6]))
    end

    it "executes in parallel" do
      list = CustomList.new([1, 2, 3])
      start_time = Time.now
      sleep_duration = 0.05

      result = list.async.map do |x|
        sleep(sleep_duration)
        x * 2
      end

      elapsed_time = Time.now - start_time

      expect(result).to be_a(CustomList)
      expect(elapsed_time).to be < (sleep_duration * 3)
    end
  end

  describe "StrictList (uses replace method)" do
    it "preserves class using replace method" do
      list = StrictList.new
      list << 1 << 2 << 3

      result = list.async.map { |x| x * 2 }
      # StrictList supports replace, so we get a StrictList back
      expect(result).to be_a(StrictList)
      expect(result.to_a).to eq([2, 4, 6])
    end
  end

  describe "Built-in collections" do
    it "still works with Set" do
      require "set"
      set = Set[1, 2, 3]
      result = set.async.map { |x| x * 2 }
      expect(result).to be_a(Set)
      expect(result).to eq(Set[2, 4, 6])
    end

    it "still works with Range" do
      range = (1..3)
      result = range.async.map { |x| x * 2 }
      expect(result).to be_a(Array)  # Ranges can't be constructed from arrays
      expect(result).to eq([2, 4, 6])
    end

    it "works with Hash enumerating over pairs" do
      hash = {a: 1, b: 2}
      result = hash.async.map { |k, v| [k, v * 2] }
      expect(result).to be_a(Hash)  # Returns a Hash when mapping key-value pairs
      expect(result).to eq({a: 2, b: 4})
    end
  end
end
