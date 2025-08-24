#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"

e = [1, 2, 3].async
puts "Async::Enumerator ancestors:"
puts e.class.ancestors.take(10).map(&:to_s).join("\n  ")

puts "\nMethod resolution for async:"
puts "Method owner: #{e.method(:async).owner}"
puts "Source: #{e.method(:async).source_location.inspect}"
