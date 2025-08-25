#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"

puts "Example: Finding Your Keys"
puts "=" * 40

rooms = [
  { name: "Kitchen", search_time: 0.3 },
  { name: "Bedroom", search_time: 0.1 },  
  { name: "Garage", search_time: 0.5 },
  { name: "Living Room", search_time: 0.2 }
]

puts "\n1. Sequential search for 'Bedroom':"
start = Time.now
found = rooms.find do |room|
  sleep(room[:search_time])  # Simulate searching
  puts "  Searched #{room[:name]} (#{room[:search_time]}s)"
  room[:name] == "Bedroom"
end
puts "  Found: #{found[:name]} in #{(Time.now - start).round(2)}s"
puts "  (Always takes 0.4s = Kitchen + Bedroom)"

puts "\n2. Async search for 'Bedroom':"
start = Time.now
found = rooms.async.find do |room|
  sleep(room[:search_time])  # Simulate searching
  room[:name] == "Bedroom"
end
puts "  Found: #{found[:name]} in #{(Time.now - start).round(2)}s"
puts "  (Takes only 0.1s - Bedroom finishes first!)"

puts "\n3. Demonstrating early termination with larger collection:"
puts "  Creating 100 servers to check..."

# Simulate checking 100 servers
servers = 100.times.map { |i| 
  { 
    name: "server-#{i}", 
    response_time: rand(0.1..2.0),
    has_data: i == 42  # Only server-42 has our data
  }
}

puts "\n  Sequential search (would take forever):"
start = Time.now
found = servers.take(5).find do |server|  # Only check first 5 for demo
  sleep(server[:response_time] / 10)  # Scale down for demo
  print "."
  server[:has_data]
end
sequential_time = Time.now - start
puts "\n  Checked 5 servers in #{sequential_time.round(2)}s"
puts "  (Full sequential scan would take ~#{(servers.sum { |s| s[:response_time] }).round}s!)"

puts "\n  Async search with max_fibers=10:"
start = Time.now
checked_count = 0
found = servers.async(max_fibers: 10).find do |server|
  sleep(server[:response_time] / 10)  # Scale down for demo
  checked_count += 1
  server[:has_data]
end
parallel_time = Time.now - start

if found
  puts "  Found data on #{found[:name]} in #{parallel_time.round(2)}s"
  puts "  Only had to start checking ~#{checked_count} servers"
  puts "  (Early termination saved us from checking all 100!)"
else
  puts "  No data found after checking all servers"
end