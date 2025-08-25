# Async::Enumerable

[![Gem Version](https://badge.fury.io/rb/async-enumerable.svg)](https://rubygems.org/gems/async-enumerable)
[![CI](https://github.com/jetpks/async-enumerable/workflows/CI/badge.svg)](https://github.com/jetpks/async-enumerable/actions)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**Make your Ruby collections actually fast ⚡**

You know that feeling when your API calls are running sequentially and you're watching your life slowly drain away? Yeah, we fixed that. This gem adds `.async` to Ruby's Enumerable, powered by [socketry/async](https://github.com/socketry/async) and [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby).

```ruby
# Before: ☕ Time for coffee...
users = user_ids.map { |id| fetch_user(id) }  # 30 seconds for 30 users

# After: ⚡ Lightning fast!
users = user_ids.async.map { |id| fetch_user(id) }  # 1 second for 30 users!
```

## Why This Doesn't Suck

- **Zero learning curve** - If you know `.map`, you know `.async.map`.
- **Actually parallel** - Your I/O happens concurrently. Not threads, not processes, just fibers doing what they do best.
- **Early termination** - `find` and `any?` bail out as soon as they can.
- **Configurable concurrency** - Limit fibers when you need to. Default when you don't care.
- **Works with ANY Enumerable** - Arrays, Ranges, Sets, that weird custom thing you built in 2019... it all works.

## Quick Install

```bash
# Add to your Gemfile
bundle add async-enumerable

# Or install directly
gem install async-enumerable
```

## Show Me The Code

### The Basics

Add `.async` to any collection and watch it go BRRRRR:

```ruby
require 'async/enumerable'

# Transform any enumerable into something useful
results = [1, 2, 3, 4, 5].async.map { |n| slow_api_call(n) }
# => [2, 4, 6, 8, 10]  (but in 1 second instead of 5)

# Works with anything Enumerable
(1..1000).async.select { |n| check_api(n) }  # Hit all the APIs at once
Set[*urls].async.map { |url| fetch(url) }
```

### Example: The Coffee Shop ☕

Let's say you're fetching data from GitHub's API (because of course you are):

```ruby
require 'async/enumerable'
require 'net/http'
require 'json'

coffee_shops = [
  { name: "Starbucks", api: "https://api.github.com/users/starbucks" },
  { name: "Blue Bottle", api: "https://api.github.com/users/bluebottle" },
  { name: "Philz", api: "https://api.github.com/users/philz" },
  { name: "Peet's", api: "https://api.github.com/users/peets" },
  { name: "Dunkin'", api: "https://api.github.com/users/dunkin" }
]

# The slow way
start = Time.now
shop_data = coffee_shops.map do |shop|
  response = Net::HTTP.get(URI(shop[:api]))
  { shop[:name] => JSON.parse(response)["public_repos"] rescue 0 }
end
puts "Sequential: #{Time.now - start} seconds"  # Go get coffee

# The async way (like you have better things to do)
start = Time.now
shop_data = coffee_shops.async.map do |shop|
  response = Net::HTTP.get(URI(shop[:api]))
  { shop[:name] => JSON.parse(response)["public_repos"] rescue 0 }
end
puts "Parallel: #{Time.now - start} seconds"  # Already done
```

### Example: Finding Your Keys 🔑

Here's something fun - `find` returns the **fastest** result, not necessarily the first:

```ruby
rooms = [
  { name: "Kitchen", search_time: 0.3 },
  { name: "Bedroom", search_time: 0.1 },  
  { name: "Garage", search_time: 0.5 },
  { name: "Living Room", search_time: 0.2 }
]

# Sequential search - always searches rooms in order
found = rooms.find do |room|
  sleep(room[:search_time])  # Simulate searching
  room[:name] == "Bedroom"
end
# Always takes 0.4 seconds (Kitchen + Bedroom)

# Async search - everyone searches at once!
found = rooms.async.find do |room|
  sleep(room[:search_time])  # Simulate searching  
  room[:name] == "Bedroom"
end
# Takes only 0.1 seconds! (Bedroom finishes first)

# With larger collections, early termination really shines:
servers = 100.times.map { |i| "server-#{i}" }

# Check servers for the one with our data
found = servers.async(max_fibers: 10).find do |server|
  response = check_server(server)  # 0.5-2 seconds each
  response[:has_data]
end
# Stops checking as soon as one server responds with data!
# The other fibers are cancelled, saving time and resources.
```

### Example: The Validator Squad ✅

Running multiple validations? Let them work in parallel:

```ruby
class EmailValidator
  include Async::Enumerable
  def_async_enumerable :@checks
  
  def initialize(email)
    @email = email
    @checks = [
      -> { check_dns_record },        # 0.5 seconds
      -> { check_disposable_domain }, # 0.3 seconds  
      -> { check_smtp_verify },       # 1.0 seconds
      -> { check_reputation }         # 0.4 seconds
    ]
  end
  
  def valid?
    # All checks must pass - but run them in parallel!
    @checks.async.all? { |check| check.call }
    # Total time: ~1.0 seconds (the slowest check)
    # Sequential would be: 2.2 seconds
  end
  
  def suspicious?
    # Stops as soon as ANY check fails
    @checks.async.any? { |check| !check.call }
  end
end
```

### Example: Data Pipeline 📈

Chain operations and stay async the whole way:

```ruby
# Processing a bunch of user records
users = User.all  # Let's say 1000 users

results = users
  .async(max_fibers: 50)  # Be nice to the database
  .select { |u| u.active? }  # Parallel filtering
  .map { |u| enrich_with_api_data(u) }  # Parallel API calls
  .reject { |u| u.data[:score] < 0.5 }  # Parallel scoring
  .sort_by { |u| -u.data[:score] }  # Sort by score
  .take(100)  # Top 100 users

# Each step runs in parallel, but waits for completion before the next step.
# Still way faster than sequential!
```

### Example: Rate-Limited API Scraper 🎯

Respect rate limits while maximizing throughput:

```ruby
class GitHubScraper
  include Async::Enumerable
  def_async_enumerable :@repos, max_fibers: 10  # GitHub rate limit friendly
  
  def initialize(org)
    @repos = fetch_repo_list(org)
  end
  
  def analyze_repos
    @repos.async.map do |repo|
      # These run in parallel, but max 10 at a time
      data = fetch_repo_details(repo)
      {
        name: repo,
        stars: data["stargazers_count"],
        language: data["language"],
        last_update: data["updated_at"]
      }
    end
  end
end

# Scrape responsibly!
scraper = GitHubScraper.new("ruby")
repo_analysis = scraper.analyze_repos  # Fast but respectful
```

## How Does It Work?

### All Your Favorite Methods, Now Actually Parallel

```ruby
# Every Enumerable method you know and love:
[1, 2, 3].async.map { |n| expensive_calc(n) }     # ⚡ Parallel map
[1, 2, 3].async.select { |n| slow_check(n) }      # ⚡ Parallel select  
[1, 2, 3].async.any? { |n| api_check(n) }         # ⚡ Stops when found!
[1, 2, 3].async.find { |n| database_lookup(n) }   # ⚡ First to finish wins!

# Chain them together:
data.async
  .select { |x| x.valid? }        # Parallel filtering
  .map { |x| transform(x) }       # Parallel transformation
  .reduce(0) { |sum, x| sum + x } # Even reduce works!
```

### Smart Early Termination 🧠

Some methods are smart enough to stop as soon as they know the answer:

- **`any?`** - Stops at first true
- **`all?`** - Stops at first false  
- **`none?`** - Stops at first true
- **`find`** - Stops when found
- **`include?`** - Stops when found

This means if you're checking 1000 items and the 3rd one matches, the other 997 can go home early.

### Including in Your Own Classes

Make your custom collections async-capable:

```ruby
class TodoList
  include Async::Enumerable
  def_async_enumerable :@todos  # Tell it what to enumerate
  
  def initialize
    @todos = []
  end
  
  def <<(todo)
    @todos << todo
    self
  end
end

list = TodoList.new
list << "Buy coffee" << "Write code" << "Ship it!"

# Now your class has async!
list.async.map { |todo| complete_todo(todo) }
```

## Things to Know

### The "Fastest Wins" Rule for `find`

With async, `find` returns the **fastest** result, not the **first** one:

```ruby
# This is actually a feature, not a bug!
[slow_api, fast_api, medium_api].async.find { |api| api.has_data? }
# Returns fast_api's data (even though it's second in the array)
```

If you need the first by position, just use regular (non-async) find.

### Comparison Works Without `.sync`

No need to call `.sync` for comparisons:

```ruby
async_result = [1, 2, 3].async.map { |x| x * 2 }
async_result == [2, 4, 6]  # => true!

# Perfect for testing:
expect(data.async.select(&:valid?)).to eq(expected_items)
```

## When to Use Async (and When Not To)

### Use Async When You Have:
- **I/O operations** - API calls, database queries, file reads
- **Network latency** - Waiting for remote services
- **Independent operations** - Each item can be processed alone
- **Multiple external systems** - Coordinating different data sources

### Skip Async When You Have:
- **Super fast operations** - Simple math, string manipulation
- **Sequential dependencies** - Each step needs the previous result
- **Tiny collections** - Overhead isn't worth it for 3 items

```ruby
# GOOD: I/O bound operations
urls.async.map { |url| HTTP.get(url) }  # 🚀 Much faster!

# BAD: CPU-bound calculations
numbers.async.map { |n| n * 2 }  # 🐢 Slower (fiber overhead)

# GOOD: I/O operations
files.async.map { |f| File.read(f) }  # 🚀 Parallel I/O!

# BAD: Sequential operations
data.async.map { |x| @sum += x }  # ❌ Don't do this!
```

## Performance 📊

We ran benchmarks with simulated I/O operations. Here's what happened:

### Collection Size Comparison

| Collection Size | Sync (i/s) | Async (i/s) | Speedup |
|----------------|------------|-------------|---------|
| 10 items       | 158.8      | 915.4       | **5.8x faster** 🚀 |
| 100 items      | 16.0       | 325.6       | **20.4x faster** 🚀🚀 |
| 1000 items     | 7.8        | 45.1        | **5.8x faster** 🚀 |

*For huge collections, tune `max_fibers` for even better performance!*

### Early Termination Performance

| Method | Scenario | Sync (i/s) | Async (i/s) | Speedup |
|--------|----------|------------|-------------|---------|
| `any?` | Early match | 265.3 | 1196.0 | **4.5x faster** ⚡ |
| `any?` | Late match | 16.4 | 355.8 | **21.8x faster** ⚡⚡ |
| `find` | Middle element | 31.8 | 413.0 | **13.0x faster** ⚡⚡ |

The takeaway? The more I/O you have, the more you'll love async.

### Fine-Tuning Performance

```ruby
# Processing 10,000 items? Control your fibers:
(1..10000).async(max_fibers: 100).map { |n| process(n) }

# Set a default for your class:
class DataProcessor
  include Async::Enumerable
  def_async_enumerable :@items, max_fibers: 50
end
```

## Learn More

📖 **[API Reference](docs/reference)** - Complete method documentation  
📚 **[Technical Details](docs/technical-details.md)** - Module architecture, configuration, patterns  
📊 **[Benchmarking Guide](docs/benchmarks.md)** - Run your own benchmarks, tuning tips  
💎 **[RubyGems Page](https://rubygems.org/gems/async-enumerable)** - Installation, version history

## Development

Want to contribute? Awesome! 🎉

```bash
bin/setup     # Install dependencies
rake spec     # Run tests
bin/console   # Play around in IRB
```

## Contributing

We'd love your help making async-enumerable even better! Check out the [issues](https://github.com/jetpks/async-enumerable/issues) or submit a PR. This project is a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Special Thanks

- [socketry/async](https://github.com/socketry/async) for the async implementation
- [concurrent-ruby](https://github.com/ruby-concurrency/concurrent-ruby) for thread-safe primitives
- You, for reading this far! 💖

## Code of Conduct

Be excellent to each other! See our [code of conduct](https://github.com/jetpks/async-enumerable/blob/main/CODE_OF_CONDUCT.md).
