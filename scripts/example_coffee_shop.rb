#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"
require "net/http"
require "json"

coffee_shops = [
  { name: "Starbucks", api: "https://api.github.com/users/starbucks" },
  { name: "Blue Bottle", api: "https://api.github.com/users/bluebottle" },
  { name: "Philz", api: "https://api.github.com/users/philz" },
  { name: "Peet's", api: "https://api.github.com/users/peets" },
  { name: "Dunkin'", api: "https://api.github.com/users/dunkin" }
]

puts "Fetching GitHub data for coffee shops..."
puts "-" * 40

# The slow way (one at a time, like it's 1999)
start = Time.now
shop_data = coffee_shops.map do |shop|
  response = Net::HTTP.get(URI(shop[:api]))
  data = JSON.parse(response) rescue {}
  { shop[:name] => data["public_repos"] || 0 }
end
sequential_time = Time.now - start
puts "Sequential: #{sequential_time.round(2)} seconds"
shop_data.each { |data| puts "  #{data}" }

puts "-" * 40

# The async way (like you have better things to do)
start = Time.now
shop_data = coffee_shops.async.map do |shop|
  response = Net::HTTP.get(URI(shop[:api]))
  data = JSON.parse(response) rescue {}
  { shop[:name] => data["public_repos"] || 0 }
end
parallel_time = Time.now - start
puts "Parallel: #{parallel_time.round(2)} seconds"
shop_data.each { |data| puts "  #{data}" }

puts "-" * 40
speedup = (sequential_time / parallel_time).round(1)
puts "Speedup: #{speedup}x faster with async!"