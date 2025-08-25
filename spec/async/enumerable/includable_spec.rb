# frozen_string_literal: true

require "spec_helper"

# Test class for real-world example specs
class TestTodoList
  include Async::Enumerable
  def_async_enumerable :todos

  Todo = Struct.new(:title, :completed, keyword_init: true)

  def initialize
    @todos = []
  end

  def add(title)
    @todos << Todo.new(title: title, completed: false)
    self
  end

  def complete(title)
    todo = @todos.find { |t| t.title == title }
    todo&.completed = true
    self
  end

  attr_reader :todos
end

RSpec.describe "Async::Enumerable includable pattern" do
  describe "basic inclusion" do
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

    it "allows a class to include Async::Enumerable" do
      collection = collection_class.new([1, 2, 3])
      expect(collection).to respond_to(:async)
    end

    it "returns an Async::Enumerable when calling async" do
      collection = collection_class.new([1, 2, 3])
      expect(collection.async.class).to include(Async::Enumerable)
    end

    it "supports async operations on the specified enumerable" do
      collection = collection_class.new([1, 2, 3, 4, 5])
      result = collection.async.map { |x| x * 2 }.sync
      expect(result).to eq([2, 4, 6, 8, 10])
    end

    it "supports chaining async operations" do
      collection = collection_class.new([1, 2, 3, 4, 5])
      result = collection.async
        .select { |x| x > 2 }
        .map { |x| x * 2 }
        .sync
      expect(result).to eq([6, 8, 10])
    end

    it "supports predicate methods" do
      collection = collection_class.new([2, 4, 6, 8])
      expect(collection.async.all? { |x| x.even? }).to be true
      expect(collection.async.any? { |x| x > 5 }).to be true
      expect(collection.async.none? { |x| x.odd? }).to be true
    end
  end

  describe "def_async_enumerable with max_fibers configuration" do
    let(:limited_collection_class) do
      Class.new do
        include Async::Enumerable
        def_async_enumerable :data, max_fibers: 2

        def initialize(data = [])
          @data = data
        end

        attr_reader :data
      end
    end

    it "respects the max_fibers limit set in def_async_enumerable" do
      collection = limited_collection_class.new((1..10).to_a)
      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      collection.async.map do |n|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep 0.01
        concurrent_count.decrement
        n * 2
      end.sync

      expect(max_concurrent.value).to be <= 2
    end

    it "allows overriding max_fibers at call time" do
      collection = limited_collection_class.new((1..10).to_a)
      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      collection.async(max_fibers: 4).map do |n|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep 0.01
        concurrent_count.decrement
        n * 2
      end.sync

      expect(max_concurrent.value).to be <= 4
      expect(max_concurrent.value).to be > 2  # Should be more than the default
    end
  end

  describe "without def_async_enumerable" do
    let(:enumerable_class) do
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

    it "uses self as the enumerable source when no def_async_enumerable is specified" do
      collection = enumerable_class.new([1, 2, 3])
      result = collection.async.map { |x| x * 2 }.sync
      expect(result).to eq([2, 4, 6])
    end
  end

  describe "with custom enumerable methods" do
    let(:custom_class) do
      Class.new do
        include Async::Enumerable
        def_async_enumerable :elements

        def initialize
          @elements = []
        end

        def add(element)
          @elements << element
          self
        end

        def elements
          @elements.dup  # Return a copy to prevent external modification
        end
      end
    end

    it "works with custom methods that modify the collection" do
      collection = custom_class.new
      collection.add("foo").add("bar").add("baz")

      result = collection.async.map(&:upcase).sync
      expect(result).to eq(["FOO", "BAR", "BAZ"])
    end
  end

  describe "real-world example: TodoList" do
    it "can process todos asynchronously" do
      list = TestTodoList.new
      list.add("Buy milk")
        .add("Write code")
        .add("Review PR")
        .complete("Write code")

      # Get all incomplete todos
      incomplete = list.async
        .reject { |todo| todo.completed }
        .map { |todo| todo.title }
        .sync

      expect(incomplete).to eq(["Buy milk", "Review PR"])
    end

    it "can check if all todos are completed" do
      list = TestTodoList.new
      list.add("Task 1").complete("Task 1")
      list.add("Task 2").complete("Task 2")

      all_done = list.async.all? { |todo| todo.completed }
      expect(all_done).to be true
    end
  end
end
