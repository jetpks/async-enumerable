#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"
require "json"
require "net/http"

# Simulated User class
User = Struct.new(:id, :name, :active, :score, :data, keyword_init: true) do
  def active?
    active
  end
  
  def to_s
    "User(#{id}: #{name}, score: #{score})"
  end
end

# Simulate fetching users from database
def fetch_users
  100.times.map do |i|
    User.new(
      id: i + 1,
      name: "User#{i + 1}",
      active: rand > 0.3,  # 70% are active
      score: nil,
      data: {}
    )
  end
end

# Simulate API enrichment
def enrich_with_api_data(user)
  sleep(rand(0.01..0.05))  # Simulate API latency
  user.data = {
    score: rand,
    verified: rand > 0.5,
    premium: rand > 0.8
  }
  user.score = user.data[:score]
  user
end

puts "Data Pipeline Example"
puts "=" * 40
puts "\nProcessing 100 users through a data pipeline..."

users = fetch_users
puts "Starting with #{users.size} users"

# Sequential processing (the old way)
puts "\n1. Sequential Processing:"
start = Time.now
sequential_results = users
  .select { |u| u.active? }
  .map { |u| enrich_with_api_data(u) }
  .reject { |u| u.data[:score] < 0.5 }
  .sort_by { |u| -u.data[:score] }
  .take(10)
sequential_time = Time.now - start

puts "  Found #{sequential_results.size} top users"
puts "  Time: #{sequential_time.round(2)}s"

# Reset users for fair comparison
users = fetch_users

# Async processing (the better way)
puts "\n2. Async Processing (with max_fibers: 20):"
start = Time.now
async_results = users
  .async(max_fibers: 20)
  .select { |u| u.active? }
  .map { |u| enrich_with_api_data(u) }
  .reject { |u| u.data[:score] < 0.5 }
  .sort_by { |u| -u.data[:score] }
  .take(10)
async_time = Time.now - start

puts "  Found #{async_results.size} top users"
puts "  Time: #{async_time.round(2)}s"

puts "\n" + "-" * 40
speedup = (sequential_time / async_time).round(1)
puts "Speedup: #{speedup}x faster with async!"

puts "\nTop 3 users:"
async_results.take(3).each_with_index do |user, i|
  puts "  #{i + 1}. #{user}"
end