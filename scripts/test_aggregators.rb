#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "async"
require "async/enumerable"

# Create a class that tracks when #each is called
class TrackedArray
  include Async::Enumerable
  def_enumerator :items

  attr_reader :items, :each_called

  def initialize(items)
    @items = items
    @each_called = false
  end
end

Sync do
  puts "Testing aggregator methods to verify they use async #each:"
  puts

  # Test reduce
  tracked = TrackedArray.new([1, 2, 3, 4, 5])
  result = tracked.async.reduce(0) do |sum, n|
    puts "  reduce: processing #{n} in fiber"
    sum + n
  end
  puts "reduce result: #{result}"
  puts

  # Test sum with block
  tracked = TrackedArray.new([1, 2, 3, 4, 5])
  result = tracked.async.sum do |n|
    puts "  sum: processing #{n} in fiber"
    n * 2
  end
  puts "sum result: #{result}"
  puts

  # Test count with block
  tracked = TrackedArray.new([1, 2, 3, 4, 5])
  result = tracked.async.count do |n|
    puts "  count: checking #{n} in fiber"
    n.even?
  end
  puts "count result: #{result}"
  puts

  # Test tally
  tracked = TrackedArray.new(%w[a b a c b a])
  result = tracked.async.tally
  puts "tally result: #{result}"
  puts

  # Test min/max with expensive comparison
  tracked = TrackedArray.new([5, 2, 8, 1, 9])
  result = tracked.async.min_by do |n|
    puts "  min_by: evaluating #{n} in fiber"
    sleep(0.1) # Simulate expensive computation
    n * -1 # Find the max by negating
  end
  puts "min_by result: #{result}"
end
