#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"

puts "Testing async chaining..."
e = [1, 2, 3].async
puts "First async: #{e.class}"
puts "Is Async::Enumerator? #{e.is_a?(Async::Enumerator)}"

# Add debug to the async method temporarily
class Async::Enumerator
  def async_debug(max_fibers: nil)
    puts "  In async method"
    puts "  self.class: #{self.class}"
    puts "  is_a?(::Async::Enumerator): #{is_a?(::Async::Enumerator)}"

    if is_a?(::Async::Enumerator)
      puts "  Returning self!"
      return self
    end

    puts "  Creating new enumerator..."
    super
  end
end

e2 = e.async_debug
puts "Second async: #{e2.class}"
puts "Same object? #{e.equal?(e2)}"
