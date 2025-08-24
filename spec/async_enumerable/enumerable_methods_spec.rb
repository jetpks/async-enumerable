require "spec_helper"

RSpec.describe "Enumerable methods with async each" do
  let(:array) { [1, 2, 3, 4, 5] }
  let(:async_array) { array.async }

  describe "filtering" do
    it "select" do
      result = async_array.select { |n| n > 2 }
      expect(result).to eq([3, 4, 5])
    end

    it "reject" do
      result = async_array.reject { |n| n > 2 }
      expect(result).to eq([1, 2])
    end

    it "find_all" do
      result = async_array.find_all { |n| n > 2 }
      expect(result).to eq([3, 4, 5])
    end

    it "filter" do
      result = async_array.filter { |n| n > 2 }
      expect(result).to eq([3, 4, 5])
    end

    it "filter_map" do
      result = async_array.filter_map { |n| n * 2 if n > 2 }
      expect(result).to eq([6, 8, 10])
    end

    it "grep" do
      strings = ["apple", "banana", "cherry"].async
      result = strings.grep(/a/)
      expect(result).to eq(["apple", "banana"])
    end

    it "grep_v" do
      strings = ["apple", "banana", "cherry"].async
      result = strings.grep_v(/a/)
      expect(result).to eq(["cherry"])
    end

    it "partition" do
      evens, odds = async_array.partition { |n| n.even? }
      expect(evens).to eq([2, 4])
      expect(odds).to eq([1, 3, 5])
    end
  end

  describe "aggregation" do
    it "reduce" do
      result = async_array.reduce(:+)
      expect(result).to eq(15)

      result = async_array.reduce(10, :+)
      expect(result).to eq(25)
    end

    it "inject" do
      result = async_array.inject { |sum, n| sum + n }
      expect(result).to eq(15)
    end

    it "sum" do
      result = async_array.sum
      expect(result).to eq(15)

      result = async_array.sum { |n| n * 2 }
      expect(result).to eq(30)
    end

    it "count" do
      expect(async_array.count).to eq(5)
      expect(async_array.count { |n| n > 2 }).to eq(3)
      expect(async_array.count(3)).to eq(1)
    end

    it "tally" do
      duplicates = [1, 2, 2, 3, 3, 3].async
      result = duplicates.tally
      expect(result).to eq({1 => 1, 2 => 2, 3 => 3})
    end
  end

  describe "min/max" do
    it "min" do
      expect(async_array.min).to eq(1)
      expect(async_array.min(2)).to eq([1, 2])
    end

    it "max" do
      expect(async_array.max).to eq(5)
      expect(async_array.max(2)).to eq([5, 4])
    end

    it "minmax" do
      expect(async_array.minmax).to eq([1, 5])
    end

    it "min_by" do
      result = async_array.min_by { |n| -n }
      expect(result).to eq(5)
    end

    it "max_by" do
      result = async_array.max_by { |n| -n }
      expect(result).to eq(1)
    end

    it "minmax_by" do
      result = async_array.minmax_by { |n| -n }
      expect(result).to eq([5, 1])
    end
  end

  describe "transformation" do
    it "collect" do
      result = async_array.collect { |n| n * 2 }
      expect(result).to eq([2, 4, 6, 8, 10])
    end

    it "flat_map" do
      result = async_array.flat_map { |n| [n, n * 2] }
      expect(result).to eq([1, 2, 2, 4, 3, 6, 4, 8, 5, 10])
    end

    it "collect_concat" do
      result = async_array.collect_concat { |n| [n, n * 2] }
      expect(result).to eq([1, 2, 2, 4, 3, 6, 4, 8, 5, 10])
    end

    it "group_by" do
      result = async_array.group_by { |n| n % 2 }
      expect(result).to eq({0 => [2, 4], 1 => [1, 3, 5]})
    end

    it "uniq" do
      duplicates = [1, 2, 2, 3, 3, 3].async
      expect(duplicates.uniq).to eq([1, 2, 3])
    end

    it "compact" do
      with_nils = [1, nil, 2, nil, 3].async
      expect(with_nils.compact).to eq([1, 2, 3])
    end
  end

  describe "ordering" do
    it "sort" do
      unsorted = [3, 1, 4, 1, 5, 9, 2, 6].async
      expect(unsorted.sort).to eq([1, 1, 2, 3, 4, 5, 6, 9])
    end

    it "sort_by" do
      result = async_array.sort_by { |n| -n }
      expect(result).to eq([5, 4, 3, 2, 1])
    end

    it "reverse_each" do
      result = []
      async_array.reverse_each { |n| result << n }
      expect(result).to eq([5, 4, 3, 2, 1])
    end
  end

  describe "slicing and dropping" do
    it "drop" do
      expect(async_array.drop(2)).to eq([3, 4, 5])
    end

    it "drop_while" do
      result = async_array.drop_while { |n| n < 4 }
      expect(result).to eq([4, 5])
    end
  end

  describe "iteration helpers" do
    it "each_with_index" do
      result = []
      async_array.each_with_index { |n, i| result << [n, i] }
      expect(result).to eq([[1, 0], [2, 1], [3, 2], [4, 3], [5, 4]])
    end

    it "each_with_object" do
      result = async_array.each_with_object([]) { |n, arr| arr << n * 2 }
      expect(result).to eq([2, 4, 6, 8, 10])
    end

    it "each_cons" do
      result = async_array.each_cons(2).to_a
      expect(result).to eq([[1, 2], [2, 3], [3, 4], [4, 5]])
    end

    it "each_slice" do
      result = async_array.each_slice(2).to_a
      expect(result).to eq([[1, 2], [3, 4], [5]])
    end

    it "cycle" do
      result = []
      [1, 2].async.cycle(2) { |n| result << n }
      expect(result).to eq([1, 2, 1, 2])
    end
  end

  describe "conversion" do
    it "entries" do
      expect(async_array.entries).to eq([1, 2, 3, 4, 5])
    end

    it "to_h" do
      pairs = [[1, "one"], [2, "two"], [3, "three"]].async
      expect(pairs.to_h).to eq({1 => "one", 2 => "two", 3 => "three"})
    end

    it "to_set" do
      require "set"
      result = async_array.to_set
      expect(result).to be_a(Set)
      expect(result.to_a.sort).to eq([1, 2, 3, 4, 5])
    end
  end

  describe "chaining and composition" do
    it "chain" do
      other = [6, 7, 8]
      result = async_array.chain(other).to_a
      expect(result).to eq([1, 2, 3, 4, 5, 6, 7, 8])
    end

    it "zip" do
      letters = ["a", "b", "c", "d", "e"]
      result = async_array.zip(letters)
      expect(result).to eq([[1, "a"], [2, "b"], [3, "c"], [4, "d"], [5, "e"]])
    end
  end

  describe "chunking" do
    it "chunk" do
      result = async_array.chunk { |n| n.even? }.to_a
      expect(result).to eq([[false, [1]], [true, [2]], [false, [3]], [true, [4]], [false, [5]]])
    end

    it "chunk_while" do
      result = async_array.chunk_while { |i, j| i + 1 == j }.to_a
      expect(result).to eq([[1, 2, 3, 4, 5]])
    end

    it "slice_before" do
      result = async_array.slice_before { |n| n > 3 }.to_a
      expect(result).to eq([[1, 2, 3], [4], [5]])
    end

    it "slice_after" do
      result = async_array.slice_after { |n| n % 2 == 0 }.to_a
      expect(result).to eq([[1, 2], [3, 4], [5]])
    end

    it "slice_when" do
      result = async_array.slice_when { |i, j| j != i + 1 }.to_a
      expect(result).to eq([[1, 2, 3, 4, 5]])
    end
  end

  describe "other" do
    it "each_entry" do
      result = []
      async_array.each_entry { |n| result << n }
      expect(result).to eq([1, 2, 3, 4, 5])
    end
  end

  describe "Hash compatibility" do
    let(:hash) { {a: 1, b: 2, c: 3} }
    let(:async_hash) { hash.async }

    it "works with Hash enumerable methods" do
      expect(async_hash.map { |k, v| [k, v * 2] }.to_h).to eq({a: 2, b: 4, c: 6})
      expect(async_hash.select { |k, v| v > 1 }.to_h).to eq({b: 2, c: 3})
      expect(async_hash.all? { |k, v| v > 0 }).to be true
    end
  end

  describe "Custom enumerable compatibility" do
    let(:custom_list_class) do
      Class.new do
        include Enumerable

        def initialize(items)
          @items = items
        end

        def each(&block)
          @items.each(&block)
        end
      end
    end

    let(:custom) { custom_list_class.new([1, 2, 3, 4, 5]) }
    let(:async_custom) { custom.async }

    it "works with custom enumerable classes" do
      expect(async_custom.map { |n| n * 2 }).to eq([2, 4, 6, 8, 10])
      expect(async_custom.select { |n| n > 2 }).to eq([3, 4, 5])
      expect(async_custom.sum).to eq(15)
    end
  end

  describe "edge cases" do
    it "handles empty collections" do
      empty = [].async
      expect(empty.all? { |n| n > 0 }).to be true
      expect(empty.any? { |n| n > 0 }).to be false
      expect(empty.none? { |n| n > 0 }).to be true
      expect(empty.sum).to eq(0)
      expect(empty.to_a).to eq([])
    end

    it "handles single element collections" do
      single = [42].async
      expect(single.all? { |n| n == 42 }).to be true
      expect(single.min).to eq(42)
      expect(single.max).to eq(42)
      expect(single.minmax).to eq([42, 42])
    end
  end
end
