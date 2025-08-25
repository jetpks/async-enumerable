# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Direct method calls on includable classes" do
  let(:collection_class) do
    Class.new do
      include Async::Enumerable
      def_async_enumerable :items

      def initialize(items = [])
        @items = items
      end

      attr_reader :items
    end
  end

  let(:collection) { collection_class.new([1, 2, 3, 4, 5]) }

  describe "predicate methods" do
    it "supports any? when called directly on the class" do
      expect(collection.any? { |x| x > 3 }).to be true
      expect(collection.any? { |x| x > 10 }).to be false
    end

    it "supports all? when called directly on the class" do
      expect(collection.all? { |x| x > 0 }).to be true
      expect(collection.all? { |x| x > 3 }).to be false
    end

    it "supports none? when called directly on the class" do
      expect(collection.none? { |x| x > 10 }).to be true
      expect(collection.none? { |x| x > 3 }).to be false
    end

    it "supports one? when called directly on the class" do
      expect(collection.one? { |x| x == 3 }).to be true
      expect(collection.one? { |x| x > 3 }).to be false
    end

    it "supports find when called directly on the class" do
      expect(collection.find { |x| x > 3 }).to eq(4)
      expect(collection.find { |x| x > 10 }).to be_nil
    end

    it "supports find_index when called directly on the class" do
      expect(collection.find_index { |x| x > 3 }).to eq(3)
      expect(collection.find_index { |x| x > 10 }).to be_nil
    end

    it "supports include? when called directly on the class" do
      expect(collection.include?(3)).to be true
      expect(collection.include?(10)).to be false
    end
  end

  describe "converter methods" do
    it "supports to_a when called directly on the class" do
      expect(collection.to_a).to eq([1, 2, 3, 4, 5])
    end
  end

  describe "with pattern matching" do
    it "supports any? with pattern" do
      expect(collection.any?(3)).to be true
      expect(collection.any?(10)).to be false
    end

    it "supports all? with pattern" do
      numbers = collection_class.new([2, 4, 6])
      expect(numbers.all?(Integer)).to be true
      expect(numbers.all?(String)).to be false
    end

    it "supports none? with pattern" do
      expect(collection.none?(10)).to be true
      expect(collection.none?(3)).to be false
    end

    it "supports one? with pattern" do
      expect(collection.one?(3)).to be true
      expect(collection.one?(Integer)).to be false
    end
  end

  describe "without block" do
    it "supports any? without block" do
      truthy_collection = collection_class.new([nil, false, 1])
      expect(truthy_collection.any?).to be true

      falsy_collection = collection_class.new([nil, false])
      expect(falsy_collection.any?).to be false
    end

    it "supports all? without block" do
      truthy_collection = collection_class.new([1, true, "text"])
      expect(truthy_collection.all?).to be true

      mixed_collection = collection_class.new([1, nil, true])
      expect(mixed_collection.all?).to be false
    end

    it "supports none? without block" do
      falsy_collection = collection_class.new([nil, false])
      expect(falsy_collection.none?).to be true

      mixed_collection = collection_class.new([nil, false, 1])
      expect(mixed_collection.none?).to be false
    end

    it "supports one? without block" do
      single_truthy = collection_class.new([nil, false, 1])
      expect(single_truthy.one?).to be true

      multiple_truthy = collection_class.new([1, 2])
      expect(multiple_truthy.one?).to be false
    end
  end

  describe "when no def_async_enumerable is specified" do
    let(:self_enumerable_class) do
      Class.new do
        include Enumerable
        include Async::Enumerable

        def initialize(items = [])
          @items = items
        end

        def each(&block)
          @items.each(&block)
        end
      end
    end

    let(:self_collection) { self_enumerable_class.new([1, 2, 3, 4, 5]) }

    it "uses self as the enumerable source for any?" do
      expect(self_collection.any? { |x| x > 3 }).to be true
    end

    it "uses self as the enumerable source for all?" do
      expect(self_collection.all? { |x| x > 0 }).to be true
    end

    it "uses self as the enumerable source for to_a" do
      expect(self_collection.to_a).to eq([1, 2, 3, 4, 5])
    end
  end
end
