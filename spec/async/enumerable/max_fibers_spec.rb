# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Async::Enumerable max_fibers" do
  describe "module-level configuration" do
    it "has a default max_fibers value of 1024" do
      expect(Async::Enumerable.max_fibers).to eq(1024)
    end

    it "allows setting max_fibers value" do
      original = Async::Enumerable.max_fibers
      Async::Enumerable.max_fibers = 50
      expect(Async::Enumerable.max_fibers).to eq(50)
      Async::Enumerable.max_fibers = original
    end
  end

  describe "per-instance configuration" do
    it "accepts max_fibers parameter in async method" do
      enum = [1, 2, 3].async(max_fibers: 10)
      expect(enum).to be_a(Async::Enumerable::AsyncEnumerator)
    end

    it "uses instance-level max_fibers over module default" do
      original = Async::Enumerable.max_fibers
      Async::Enumerable.max_fibers = 100

      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      # Test with instance limit of 5
      (1..20).async(max_fibers: 5).each do |_|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep(0.01) # Small delay to ensure fibers accumulate
        concurrent_count.decrement
      end

      # With max_fibers of 5, we shouldn't exceed 5 concurrent fibers
      expect(max_concurrent.value).to be <= 5
      expect(max_concurrent.value).to be >= 1

      Async::Enumerable.max_fibers = original
    end
  end

  describe "fiber limiting behavior" do
    it "limits concurrent fiber creation" do
      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      # Use a small limit to make testing easier
      (1..20).async(max_fibers: 3).each do |_|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep(0.01) # Small delay to ensure fibers accumulate
        concurrent_count.decrement
      end

      # Should not exceed the max_fibers limit
      expect(max_concurrent.value).to be <= 3
      expect(max_concurrent.value).to be >= 1
    end

    it "processes all items even with fiber limit" do
      processed = Concurrent::Array.new

      (1..10).async(max_fibers: 2).each do |n|
        processed << n
        sleep(0.001)
      end

      expect(processed.to_a.sort).to eq((1..10).to_a)
    end

    it "applies fiber limit to map operations" do
      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      result = (1..20).async(max_fibers: 4).map do |n|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep(0.01)
        concurrent_count.decrement
        n * 2
      end

      expect(max_concurrent.value).to be <= 4
      expect(result).to eq((1..20).map { |n| n * 2 })
    end

    it "applies fiber limit to early terminable methods" do
      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      result = (1..20).async(max_fibers: 3).any? do |n|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep(0.01)
        concurrent_count.decrement
        n > 10
      end

      expect(max_concurrent.value).to be <= 3
      expect(result).to be true
    end

    it "respects fiber limit with find operation" do
      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      result = (1..20).async(max_fibers: 2).find do |n|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep(0.01)
        concurrent_count.decrement
        n > 5
      end

      expect(max_concurrent.value).to be <= 2
      expect(result).to be > 5
    end

    it "handles large collections without creating too many fibers" do
      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      # Process a large collection with a reasonable fiber limit
      result = (1..1000).async(max_fibers: 10).map do |n|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        # Simulate very fast operation
        concurrent_count.decrement
        n
      end

      expect(max_concurrent.value).to be <= 10
      expect(result.size).to eq(1000)
    end
  end

  describe "default behavior without explicit limit" do
    it "uses module default when no instance limit specified" do
      original = Async::Enumerable.max_fibers
      Async::Enumerable.max_fibers = 7

      concurrent_count = Concurrent::AtomicFixnum.new(0)
      max_concurrent = Concurrent::AtomicFixnum.new(0)

      (1..20).async.each do |_|
        current = concurrent_count.increment
        max_concurrent.update { |v| [v, current].max }
        sleep(0.01)
        concurrent_count.decrement
      end

      expect(max_concurrent.value).to be <= 7

      Async::Enumerable.max_fibers = original
    end
  end
end
