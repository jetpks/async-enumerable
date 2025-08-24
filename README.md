# Async::Enumerable

Async::Enumerable extends Ruby's Enumerable module with asynchronous
capabilities, allowing you to perform operations in parallel using the
[socketry/async](https://github.com/socketry/async) library.

## Installation

In your bundler-managed project, run
```bash
bundle add async-enumerable
```

Or to install globally:
```bash
gem install async-enumerable
```

## Usage

Async::Enumerable adds an `.async` method to any Enumerable object, which returns
an AsyncEnumerator that performs operations in parallel:

```ruby
require 'async/enumerable'

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

The main benefit of Async::Enumerable is parallel execution of block operations:

```ruby
require 'async/enumerable'
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

Async::Enumerable supports **all** Enumerable methods through different strategies:

#### Methods with Async Implementations

Most Enumerable methods work automatically through the async implementation of `each`:
- `map`, `select`, `reject`, `collect`, `filter`, `filter_map`
- `reduce`, `inject`, `sum`, `min`, `max`, `minmax`
- `count`, `tally`, `group_by`, `partition`
- `sort`, `sort_by`, `uniq`, `compact`
- `to_a`, `to_h`, `entries`
- `each_with_index`, `each_with_object`, `with_index`
- `zip`, `cycle`, `chunk`, `slice_*`

These methods automatically benefit from parallel execution when blocks contain
I/O or expensive operations.

#### Methods with Optimized Early Termination

The EarlyTerminable module provides optimized implementations that stop
processing as soon as the result is determined:

- `all?` - Returns true if all elements match (stops on first false)
- `any?` - Returns true if any element matches (stops on first true)
- `none?` - Returns true if no elements match (stops on first true)
- `one?` - Returns true if exactly one element matches
- `include?` / `member?` - Check if collection includes a value
- `find` / `detect` - Find first matching element*
- `find_index` - Find index of matching element*

#### Methods Delegated to Synchronous Implementation

Some methods are inherently sequential and are delegated back to the wrapped enumerable:
- `first` - Takes elements from the beginning
- `take` - Takes first n elements
- `take_while` - Must evaluate elements in order
- `lazy` - Returns a standard lazy enumerator (lazy evaluation uses break internally, incompatible with async)

### When to Use Async

Async::Enumerable is beneficial when:
- Operations in the block are I/O bound (network requests, file operations)
- You have a large collection with expensive operations per element

Async::Enumerable may not help (and could be slower) when:
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

When operations involve IO (simulated with sleep delays), async methods show significant performance improvements that scale with collection size:

#### Collection Size Comparison

| Collection Size | Sync (i/s) | Async (i/s) | Speedup |
|----------------|------------|-------------|---------|
| 10 items       | 159.8      | 924.7       | **5.8x faster** |
| 100 items      | 15.8       | 325.2       | **20.6x faster** |
| 1000 items     | 7.8        | 44.7        | **5.8x faster** |

*Note: For 1000+ items, using `max_fibers` can provide additional optimization*

#### Early Termination Performance

Even methods that can terminate early benefit from async execution:

| Method | Scenario | Sync (i/s) | Async (i/s) | Speedup |
|--------|----------|------------|-------------|---------|
| `any?` | Early match | 265.5 | 1190.9 | **4.5x faster** |
| `any?` | Late match | 16.5 | 351.8 | **21.3x faster** |
| `find` | Middle element | 31.8 | 412.5 | **13.0x faster** |

#### Max Fibers Configuration

For very large collections, limiting concurrent fibers can improve performance:

```ruby
# Default (1024 fibers max)
(1..10000).async.map { |n| process(n) }

# Limited to 100 concurrent fibers
(1..10000).async(max_fibers: 100).map { |n| process(n) }

# Configure global default
Async::Enumerable.max_fibers = 100
```

### Running Benchmarks

```bash
# Run detailed benchmarks with organized comparisons
bundle exec rake benchmark

# Run quick performance overview
bundle exec rake benchmark_quick

# Run specific benchmark files
bundle exec benchmark-driver benchmark/size_comparison/map_100.yaml
bundle exec benchmark-driver benchmark/early_termination/any_early.yaml
```

### Benchmark Structure

The benchmarks are organized into two categories:

#### Size Comparison Benchmarks (`benchmark/size_comparison/`)
Compare sync vs async performance across different collection sizes (10, 100, 1000, 10000 items):
- **map_*.yaml** - Tests parallel transformation performance at different scales

#### Early Termination Benchmarks (`benchmark/early_termination/`)
Test methods that can stop processing early:
- **any_early.yaml** - Tests `any?` with early match
- **any_late.yaml** - Tests `any?` with late match  
- **find_middle.yaml** - Tests `find` with middle element match

The benchmarks simulate IO operations using scaled sleep delays to demonstrate real-world performance benefits.

### Writing Custom Benchmarks

You can create your own benchmarks using benchmark-driver's YAML format:

```yaml
prelude: |
  require 'async/enumerable'
  
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

Bug reports and pull requests are welcome on GitHub at https://github.com/jetpks/async-enumerable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/jetpks/async-enumerable/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Async::Enumerable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/jetpks/async-enumerable/blob/main/CODE_OF_CONDUCT.md).
