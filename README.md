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
an Async::Enumerator that performs operations in parallel:

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

### Including in Your Classes

Async::Enumerable can be included in your own classes to add async capabilities:

```ruby
class TodoList
  include Async::Enumerable
  def_async_enumerable :@todos  # Specify which ivar/method returns the enumerable
  
  def initialize
    @todos = []
  end
  
  def add(todo)
    @todos << todo
    self
  end
  
  attr_reader :todos
end

list = TodoList.new
list.add("Buy milk").add("Write code").add("Review PR")

# Process todos asynchronously
completed = list.async.map { |todo| process_todo(todo) }.sync
```

You can also specify a default fiber limit for your class:

```ruby
class ApiClient
  include Async::Enumerable
  def_async_enumerable :@endpoints, max_fibers: 10  # Limit concurrent requests
  
  attr_reader :endpoints
end
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

The Predicates module provides optimized implementations that stop
processing as soon as the result is determined:

- `all?` - Returns true if all elements match (stops on first false)
- `any?` - Returns true if any element matches (stops on first true)
- `none?` - Returns true if no elements match (stops on first true)
- `one?` - Returns true if exactly one element matches
- `include?` / `member?` - Check if collection includes a value
- `find` / `detect` - Find first matching element *
- `find_index` - Find index of matching element *

**\* Important:** `find` and `find_index` return the **fastest completing** result, not necessarily the **first** element in order. See [Parallel Execution Behavior](#parallel-execution-behavior) below.

#### Methods Delegated to Synchronous Implementation

Some methods are inherently sequential and are delegated back to the wrapped enumerable:
- `first` - Takes elements from the beginning
- `take` - Takes first n elements
- `take_while` - Must evaluate elements in order
- `lazy` - Returns a standard lazy enumerator (lazy evaluation uses break internally, incompatible with async)

### Method Chaining

Async::Enumerator maintains the async context through method chains. Transformation methods like `map`, `select`, and `reject` return new `Async::Enumerator` instances, allowing you to chain multiple operations while staying in "async land":

```ruby
# Chain stays async until .sync
result = [1, 2, 3, 4, 5].async
                        .map { |x| expensive_operation(x) }    # Returns Async::Enumerator
                        .select { |x| x > threshold }          # Returns Async::Enumerator
                        .map { |x| transform(x) }              # Returns Async::Enumerator
                        .sync                                   # Returns Array

# The .sync method explicitly converts back to an array
data = urls.async
           .map { |url| fetch_data(url) }
           .select { |data| data.valid? }
           .sync  # Get final results as array
```

Async::Enumerator also implements comparison operators, so it can be compared directly with arrays:

```ruby
# Equality comparison works without .sync
async_result = [1, 2, 3].async.map { |x| x * 2 }
async_result == [2, 4, 6]  # => true

# This makes testing clean and simple
expect(data.async.select { |x| x.valid? }).to eq(expected_valid_items)
```

### Module Structure

Async::Enumerable is organized into logical modules for better maintainability and selective inclusion:

- **`Async::Enumerable::Methods::Transformers`** - Methods that transform collections (map, select, reject, etc.)
- **`Async::Enumerable::Methods::Predicates`** - Methods that test conditions with early termination (all?, any?, none?, one?, include?, find, find_index)
- **`Async::Enumerable::Methods::Converters`** - Methods that convert to other types (to_a, sync)
- **`Async::Enumerable::Methods::Aggregators`** - Aggregation methods inherited from Enumerable (reduce, sum, count, etc.)
- **`Async::Enumerable::Methods::Iterators`** - Iteration helpers inherited from Enumerable (each_with_index, each_cons, etc.)
- **`Async::Enumerable::Methods::Slicers`** - Slicing/filtering methods inherited from Enumerable (drop, grep, partition, etc.)
- **`Async::Enumerable::ConcurrencyBounder`** - Cross-cutting concern for limiting concurrent fibers
- **`Async::Enumerable::Configurable`** - Configuration management system with hierarchical config inheritance and collection resolution
- **`Async::Enumerable::Comparable`** - Comparison operators for async enumerators

You can selectively include specific modules if needed:

```ruby
class CustomAsync
  include Enumerable
  include Async::Enumerable::Methods::Transformers::Map
  include Async::Enumerable::Methods::Converters::Sync
  include Async::Enumerable::ConcurrencyBounder
  
  # Only has async map and sync methods
end
```

### Parallel Execution Behavior

Due to the parallel nature of async operations, some methods behave differently than their synchronous counterparts:

#### Find and Find_index Return Fastest Result

When using `find`, `detect`, or `find_index` with async enumeration, the result returned is the **first to complete evaluation**, not necessarily the first element in the collection order:

```ruby
# Synchronous - always returns 3 (first element > 2)
[1, 2, 3, 4, 5].find { |n| n > 2 }  # => 3

# Async - returns whichever completes first
[1, 2, 3, 4, 5].async.find { |n| 
  sleep(6 - n)  # Element 5 completes first
  n > 2 
}  # => Could be 3, 4, or 5 (likely 5 due to shorter sleep)
```

This is a performance optimization - as soon as any matching element is found, the search terminates immediately without waiting for earlier elements to complete.

#### When Order Matters

If you need the **first element by position** rather than the **fastest to evaluate**, you have several options:

```ruby
# Option 1: Use synchronous enumeration
collection.find { |item| expensive_check(item) }

# Option 2: Process in order then find
collection.async.map { |item| [item, expensive_check(item)] }
          .find { |item, result| result }
          &.first

# Option 3: Use with_index to track position
matches = collection.async.filter_map.with_index do |item, index|
  expensive_check(item) ? [index, item] : nil
end
first_match = matches.min_by { |index, _| index }&.last
```

This behavior applies to:
- `find` / `detect` - Returns fastest matching element
- `find_index` - Returns index of fastest matching element

Other predicates like `all?`, `any?`, `none?`, `one?`, and `include?` return boolean values, so the order doesn't affect the result.

### When to Use Async

Async::Enumerable is beneficial when:
- Operations in the block are I/O bound (network requests, file operations)
- You have a large collection with expensive operations per element
- The order of results doesn't matter, or you're collecting all results

Async::Enumerable may not help (and could be slower) when:
- Operations are very fast/simple
- Order of execution matters (for find/find_index)
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
Async::Enumerable.configure { |c| c.max_fibers = 100 }

# Configure at class level
class MyClass
  include Async::Enumerable
  def_async_enumerable :@data, max_fibers: 50
end
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
