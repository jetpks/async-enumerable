# AsyncEnumerable

AsyncEnumerable extends Ruby's Enumerable module with asynchronous capabilities, allowing you to perform operations in parallel using the [socketry/async](https://github.com/socketry/async) library.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'async_enumerable'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install async_enumerable
```

## Usage

AsyncEnumerable adds an `.async` method to any Enumerable object, which returns an AsyncEnumerator that performs operations in parallel:

```ruby
require 'async_enumerable'

# Convert any enumerable to async
results = [1, 2, 3, 4, 5].async.map { |n| n * 2 }
# => [2, 4, 6, 8, 10]

# Works with any enumerable
(1..100).async.select { |n| expensive_check(n) }

# Chain async operations
data.async
  .select { |item| item.valid? }
  .map { |item| process(item) }
  .take(10)
```

### Parallel Execution

The main benefit of AsyncEnumerable is parallel execution of block operations:

```ruby
require 'async_enumerable'
require 'net/http'

urls = [
  'https://api.github.com/users/ruby',
  'https://api.github.com/users/rails',
  'https://api.github.com/users/matz'
]

# Synchronous - requests made sequentially
responses = urls.map do |url|
  Net::HTTP.get(URI(url))
end

# Asynchronous - requests made in parallel
responses = urls.async.map do |url|
  Net::HTTP.get(URI(url))
end
```

### Supported Methods

AsyncEnumerable provides async implementations for methods that can benefit from parallel execution:

#### Iteration
- `each` - Execute block for each element in parallel

#### Short-Circuit Methods (with early termination)
- `all?` - Returns true if all elements match (stops on first false)
- `any?` - Returns true if any element matches (stops on first true)
- `none?` - Returns true if no elements match (stops on first true)
- `one?` - Returns true if exactly one element matches
- `include?` / `member?` - Check if collection includes a value
- `find` / `detect` - Find first matching element
- `find_index` - Find index of first matching element

#### Collection Methods
- `first(n)` - Get first n elements
- `take(n)` - Take first n elements

#### Methods that delegate to synchronous implementation
- `take_while` - Sequential by nature, cannot be parallelized
- `lazy` - Returns a standard lazy enumerator

### When to Use Async

AsyncEnumerable is beneficial when:
- Operations in the block are I/O bound (network requests, file operations)
- Operations are CPU-intensive and independent
- You have a large collection with expensive operations per element

AsyncEnumerable may not help (and could be slower) when:
- Operations are very fast/simple
- Order of execution matters
- Operations depend on previous results
- The overhead of concurrency exceeds the operation cost

### Examples

#### Parallel API Requests
```ruby
user_ids = [1, 2, 3, 4, 5]

# Fetch user data in parallel
users = user_ids.async.map do |id|
  fetch_user_from_api(id)
end
```

#### Parallel File Processing
```ruby
file_paths = Dir.glob("*.txt")

# Process files in parallel
results = file_paths.async.map do |path|
  process_file(File.read(path))
end
```

#### Early Termination with any?
```ruby
# Stops as soon as one valid item is found
has_valid = items.async.any? do |item|
  expensive_validation(item)
end
```

#### Finding in Parallel
```ruby
# Searches in parallel, stops when found
result = large_dataset.async.find do |record|
  complex_matching_logic(record)
end
```

## Benchmarks

The gem includes benchmarks that demonstrate the performance characteristics of async operations compared to synchronous ones.

### Performance Results

When operations involve IO (simulated with 0-1ms delays), async methods show significant performance improvements:

#### Map Operations (100 elements)
```
                      user     system      total        real
sync map:         0.000156   0.000256   0.000412 (  0.063224)
async map:        0.001232   0.000888   0.002120 (  0.003755)
```
**~17x faster** with async when operations involve IO

#### Select Operations (100 elements)
```
                      user     system      total        real
sync select:      0.000145   0.000276   0.000421 (  0.060473)
async select:     0.001135   0.000501   0.001636 (  0.003498)
```
**~17x faster** with async for filtering operations

#### Early Termination (any? with 100 elements)
```
                      user     system      total        real
sync any?:        0.000013   0.000030   0.000043 (  0.005060)
async any?:       0.000627   0.000304   0.000931 (  0.001948)
```
**~2.6x faster** even with early termination

#### Iterations per Second Comparison (benchmark-driver)
```
Comparison:
         async_small:       934.6 i/s 
        async_medium:       533.0 i/s - 1.75x  slower
         async_large:       334.6 i/s - 2.79x  slower
          sync_small:       158.3 i/s - 5.90x  slower
         sync_medium:        31.6 i/s - 29.54x  slower
          sync_large:        16.0 i/s - 58.54x  slower
```

For large collections (100 elements) with IO operations, **async is ~21x faster** than sync.

### Running Benchmarks

```bash
# Run simple comparison benchmark
bundle exec rake benchmark

# Run detailed benchmarks with benchmark-driver
bundle exec rake benchmark_driver

# Run specific benchmark files
bundle exec benchmark-driver benchmark/async_map.yml
```

### Benchmark Structure

The benchmarks simulate IO operations using `sleep(rand/1000)` to create 0-1ms delays, similar to real-world IO latency. This helps demonstrate when async operations provide benefits:

- **async_map.yml** - Parallel transformation of collections
- **async_select.yml** - Parallel filtering operations
- **async_any.yml** - Early termination with parallel search
- **async_find.yml** - Finding elements with early termination
- **async_all.yml** - Validation with early termination on failure
- **async_each.yml** - Parallel side effects

### Writing Custom Benchmarks

You can create your own benchmarks using benchmark-driver's YAML format:

```yaml
prelude: |
  require 'async_enumerable'
  
  def expensive_operation(n)
    sleep(rand / 100.0) # Simulate 0-10ms IO
    n * 2
  end
  
  data = (1..100).to_a

benchmark:
  sync: data.map { |n| expensive_operation(n) }
  async: data.async.map { |n| expensive_operation(n) }
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jetpks/async_enumerable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/jetpks/async_enumerable/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AsyncEnumerable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jetpks/async_enumerable/blob/main/CODE_OF_CONDUCT.md).