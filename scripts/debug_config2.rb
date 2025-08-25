#!/usr/bin/env ruby
require_relative "../lib/async/enumerable"

# Check initial state
puts "=== Initial state ==="
puts "Module config: #{Async::Enumerable.config.max_fibers}"
puts "Enumerator class config: #{Async::Enumerator.__async_enumerable_config.max_fibers if Async::Enumerator.respond_to?(:__async_enumerable_config)}"

# Now configure module
puts "\n=== After configuring module ==="
Async::Enumerable.configure { |c| c.max_fibers = 50 }
puts "Module config: #{Async::Enumerable.config.max_fibers}"
puts "Enumerator class config: #{Async::Enumerator.__async_enumerable_config.max_fibers if Async::Enumerator.respond_to?(:__async_enumerable_config)}"

# Create a fresh class that includes Async::Enumerable
puts "\n=== Creating fresh class after module config ==="
class TestClass
  include Async::Enumerable
  def_async_enumerable :@data
  
  def initialize
    @data = [1, 2, 3]
  end
end

puts "TestClass config: #{TestClass.__async_enumerable_config.max_fibers}"

# Create instance
puts "\n=== Creating instances ==="
enum = Async::Enumerator.new([1, 2, 3])
puts "Enumerator instance config: #{enum.__async_enumerable_config.max_fibers}"

test = TestClass.new
puts "TestClass instance config: #{test.__async_enumerable_config.max_fibers}"