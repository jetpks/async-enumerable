#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/async/enumerable"

# Example class that includes Async::Enumerable
class TodoList
  include Async::Enumerable
  def_enumerator :todos

  def initialize
    @todos = []
  end

  attr_reader :todos

  def add(todo)
    @todos << todo
  end
end

# Test the new functionality
list = TodoList.new
list.add("Buy milk")
list.add("Write code")
list.add("Review PR")

puts "Testing def_enumerator with TodoList:"
results = list.async.map { |todo| "✓ #{todo}" }.sync
puts results.inspect

# Test that regular arrays still work
puts "\nTesting regular array async:"
array_results = [1, 2, 3].async.map { |n| n * 2 }.sync
puts array_results.inspect

puts "\nAll tests passed!"
