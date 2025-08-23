#!/usr/bin/env ruby
# frozen_string_literal: true

require 'benchmark'
require_relative '../lib/async_enumerable'

# Simulate IO operations with random delays
def io_operation(n)
  sleep(rand / 1000.0) # Sleep 0-1ms to simulate IO
  n * 2
end

def expensive_check(n)
  sleep(rand / 1000.0) # Sleep 0-1ms to simulate IO
  n % 10 == 0
end

puts "AsyncEnumerable Benchmark Comparison"
puts "=" * 50
puts "Simulating IO operations with 0-1ms delays"
puts

# Test different array sizes
[10, 50, 100].each do |size|
  array = (1..size).to_a
  
  puts "\nArray size: #{size} elements"
  puts "-" * 30
  
  Benchmark.bm(15) do |x|
    # Map benchmark
    x.report("sync map:") do
      array.map { |n| io_operation(n) }
    end
    
    x.report("async map:") do
      array.async.map { |n| io_operation(n) }
    end
    
    # Select benchmark
    x.report("sync select:") do
      array.select { |n| expensive_check(n) }
    end
    
    x.report("async select:") do
      array.async.select { |n| expensive_check(n) }
    end
    
    # Any? benchmark (with early termination)
    x.report("sync any?:") do
      array.any? { |n| expensive_check(n) }
    end
    
    x.report("async any?:") do
      array.async.any? { |n| expensive_check(n) }
    end
    
    # Find benchmark (with early termination)
    target = size / 2
    x.report("sync find:") do
      array.find { |n| n == target }
    end
    
    x.report("async find:") do
      array.async.find { |n| sleep(rand / 1000.0); n == target }
    end
  end
end

puts "\n" + "=" * 50
puts "Note: Async methods show performance benefits when:"
puts "  - Operations involve IO (network, disk, etc.)"
puts "  - Operations are CPU-intensive and independent"
puts "  - Collection size is large enough to offset async overhead"