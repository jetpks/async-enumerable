#!/usr/bin/env ruby
# Test script to demonstrate issue #7 - methods referencing @enumerable directly

require_relative "../lib/async/enumerable"

class MyCollection
  include Async::Enumerable
  def_enumerator :items

  def initialize
    @items = [1, 2, 3, 4, 5]
  end

  attr_reader :items
end

collection = MyCollection.new
puts "Collection responds to any?: #{collection.respond_to?(:any?)}"
puts "Collection.async responds to any?: #{collection.async.respond_to?(:any?)}"

# Try calling any? directly on the collection (not through async)
begin
  result = collection.any? { |x| x > 3 }
  puts "Direct any? result: #{result}"
rescue => e
  puts "Direct any? error: #{e.message}"
  puts "  Backtrace: #{e.backtrace.first(3).join("\n  ")}"
end

# Try calling through async (should work)
begin
  result = collection.async.any? { |x| x > 3 }
  puts "Async any? result: #{result}"
rescue => e
  puts "Async any? error: #{e.message}"
end

puts "\n--- Testing all? method ---"
# Try all? directly
begin
  result = collection.all? { |x| x > 0 }
  puts "Direct all? result: #{result}"
rescue => e
  puts "Direct all? error: #{e.message}"
end

# Try all? through async
begin
  result = collection.async.all? { |x| x > 0 }
  puts "Async all? result: #{result}"
rescue => e
  puts "Async all? error: #{e.message}"
end
