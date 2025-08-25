#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/async/enumerable"
require "net/http"
require "json"

class GitHubScraper
  include Async::Enumerable
  def_async_enumerable :@repos, max_fibers: 10  # GitHub rate limit friendly
  
  def initialize(org)
    @org = org
    @repos = fetch_repo_list(org)
  end
  
  def fetch_repo_list(org)
    puts "Fetching repository list for #{org}..."
    # For demo, we'll just use some known Ruby repos
    [
      "ruby/ruby",
      "rails/rails", 
      "jekyll/jekyll",
      "discourse/discourse",
      "hashicorp/vagrant",
      "github/scientist",
      "rubocop/rubocop",
      "puma/puma",
      "sinatra/sinatra",
      "rspec/rspec"
    ]
  end
  
  def fetch_repo_details(repo)
    uri = URI("https://api.github.com/repos/#{repo}")
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  rescue => e
    puts "  Error fetching #{repo}: #{e.message}"
    {}
  end
  
  def analyze_repos
    puts "\nAnalyzing #{@repos.size} repositories (max 10 concurrent requests)..."
    
    results = @repos.async.map do |repo|
      print "."
      data = fetch_repo_details(repo)
      {
        name: repo.split("/").last,
        stars: data["stargazers_count"] || 0,
        language: data["language"] || "Unknown",
        last_update: data["updated_at"] || "Unknown"
      }
    end
    
    puts "\n"
    results
  end
end

puts "Rate-Limited API Scraper Example"
puts "=" * 40

# Without rate limiting (for comparison - don't actually run this!)
puts "\nWithout rate limiting (would hammer the API):"
puts "  ❌ 10 repos × instant requests = angry GitHub"
puts "  ❌ Possible rate limit errors"
puts "  ❌ Your IP might get temporarily banned"

# With rate limiting
puts "\nWith max_fibers: 10 (respectful scraping):"
start = Time.now
scraper = GitHubScraper.new("ruby")
repo_analysis = scraper.analyze_repos
elapsed = Time.now - start

puts "Fetched #{repo_analysis.size} repos in #{elapsed.round(2)}s"
puts "\nTop 5 repositories by stars:"
repo_analysis
  .sort_by { |r| -r[:stars] }
  .take(5)
  .each_with_index do |repo, i|
    puts "  #{i + 1}. #{repo[:name]}: ⭐ #{repo[:stars]} (#{repo[:language]})"
  end

puts "\nNote: max_fibers ensures we never have more than 10 requests in flight"
puts "      This respects GitHub's rate limits while maximizing throughput!"