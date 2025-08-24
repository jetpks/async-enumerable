#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"

e = [1, 2, 3].async
puts "First async: #{e.class}"

# Check which async method is defined
puts "\nMethod owner: #{e.method(:async).owner}"
puts "Method source location: #{e.method(:async).source_location.inspect}"

# Check class methods
puts "\nClass responds to enumerable_source? #{e.class.respond_to?(:enumerable_source)}"
puts "Enumerable source: #{e.class.enumerable_source.inspect}" if e.class.respond_to?(:enumerable_source)
