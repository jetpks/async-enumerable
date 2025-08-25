#!/usr/bin/env ruby
require_relative "../lib/async/enumerable"

# Test 1: Module config
puts "=== Test 1: Module config ==="
puts "Before configure: #{Async::Enumerable.config.max_fibers}"
Async::Enumerable.configure { |c| c.max_fibers = 50 }
puts "After configure: #{Async::Enumerable.config.max_fibers}"

# Test 2: Create enumerator with no config
puts "\n=== Test 2: Enumerator with no config ==="
enum = Async::Enumerator.new([1, 2, 3])
puts "Enumerator config: #{enum.__async_enumerable_config.max_fibers}"
puts "Module config: #{Async::Enumerable.config.max_fibers}"

# Test 3: Check config_ref
puts "\n=== Test 3: Config ref details ==="
puts "Enumerator config_ref: #{enum.__async_enumerable_config_ref}"
puts "Enumerator config_ref.get: #{enum.__async_enumerable_config_ref.get}"
puts "Module config_ref: #{Async::Enumerable.config_ref}"
puts "Module config_ref.get: #{Async::Enumerable.config_ref.get}"

# Test 4: Check merge_all_config
puts "\n=== Test 4: Merge all config ==="
merged = enum.__async_enumerable_merge_all_config
puts "Merged config: #{merged}"