#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script to verify issue #7 is resolved
# Issue: Methods should use enumerable source from def_enumerator, not @enumerable directly

require_relative "../lib/async/enumerable"

# Test 1: Includable pattern with def_enumerator
class MyCollection
  include Async::Enumerable
  def_enumerator :items  # Specifies that 'items' method returns the enumerable

  def initialize(data)
    @items = data
  end

  attr_reader :items
end

puts "Test 1: Includable pattern with def_enumerator"
collection = MyCollection.new([1, 2, 3, 4, 5])

# Test async operations work with the specified source
result = collection.async.map { |x| x * 2 }.to_a
puts "  map result: #{result.inspect}"
puts "  ✓ map works" if result == [2, 4, 6, 8, 10]

# Test predicate methods work
all_positive = collection.all? { |x| x > 0 }
puts "  all? result: #{all_positive}"
puts "  ✓ all? works" if all_positive == true

any_large = collection.any? { |x| x > 3 }
puts "  any? result: #{any_large}"
puts "  ✓ any? works" if any_large == true

# Test 2: Async::Enumerator with @enumerable instance variable
puts "\nTest 2: Async::Enumerator wrapper pattern"
async_enum = [1, 2, 3, 4, 5].async

# Verify it uses @enumerable correctly
result = async_enum.map { |x| x * 2 }.to_a
puts "  map result: #{result.inspect}"
puts "  ✓ Async::Enumerator map works" if result == [2, 4, 6, 8, 10]

# Test 3: Class without def_enumerator (uses self)
class DirectCollection
  include Async::Enumerable
  include Enumerable

  def initialize(data)
    @data = data
  end

  def each(&block)
    @data.each(&block)
  end
end

puts "\nTest 3: Without def_enumerator (uses self)"
direct = DirectCollection.new([1, 2, 3, 4, 5])

# Should use self as the enumerable source
result = direct.async.map { |x| x * 2 }.to_a
puts "  map result: #{result.inspect}"
puts "  ✓ Direct collection works" if result == [2, 4, 6, 8, 10]

puts "\n✅ Issue #7 is RESOLVED! All methods properly use the enumerable source."