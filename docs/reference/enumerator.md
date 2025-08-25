# Async::Enumerator

The `Async::Enumerator` class is a wrapper that provides asynchronous implementations of Enumerable methods for parallel execution.

## Overview

This class wraps any Enumerable object and provides async versions of standard enumerable methods. It includes the standard Enumerable module for compatibility, as well as specialized async implementations through the Async::Enumerable module.

The Enumerator maintains a reference to the original enumerable and delegates method calls while providing concurrent execution capabilities through the async runtime.

## Creating an Async::Enumerator

### Direct Instantiation

```ruby
async_enum = Async::Enumerator.new([1, 2, 3, 4, 5])
async_enum.map { |n| n * 2 }  # Executes in parallel
```

### Using Enumerable#async (Preferred)

The preferred way to create an Async::Enumerator:

```ruby
result = [1, 2, 3].async.map { |n| slow_operation(n) }
```

### With Configuration

```ruby
# With custom fiber limit
huge_dataset.async(max_fibers: 100).map { |n| process(n) }

# With config object
config = Async::Enumerable::Configurable::Config.new(max_fibers: 50)
enumerator = Async::Enumerator.new(data, config)
```

## Initialization

### Parameters

- `enumerable` (Enumerable): Any object that includes Enumerable
- `config` (Config, nil): Configuration object containing settings like max_fibers
- `**kwargs`: Configuration options passed as keyword arguments (e.g., max_fibers: 100)

### Examples

```ruby
# Default configuration
async_array = Async::Enumerator.new([1, 2, 3])

# Custom fiber limit via kwargs
async_range = Async::Enumerator.new(1..100, max_fibers: 50)

# With config object
config = Async::Enumerable::Configurable::Config.new(max_fibers: 100)
async_enum = Async::Enumerator.new(data, config)

# Override config with kwargs
async_enum = Async::Enumerator.new(data, config, max_fibers: 200)
```

## Core Methods

### each

Asynchronously iterates over each element in the enumerable, executing the given block in parallel for each item.

This method spawns async tasks for each item in the enumerable, allowing them to execute concurrently. It uses an `Async::Barrier` to coordinate the tasks and waits for all of them to complete before returning.

When called without a block, returns an Enumerator for compatibility with the standard Enumerable interface.

#### Parameters
- `&block`: Block to execute for each element in parallel

#### Returns
- With block: Returns self (for chaining)
- Without block: Returns an Enumerator

#### Examples

```ruby
# Basic async iteration
[1, 2, 3].async.each do |n|
  puts "Processing #{n}"
  sleep(1)  # All three will complete in ~1 second total
end

# With I/O operations
urls.async.each do |url|
  response = HTTP.get(url)
  save_to_cache(url, response)
end
# All URLs are fetched and cached concurrently

# Chaining
data.async
    .each { |item| log(item) }
    .map { |item| transform(item) }
```

#### Important Notes
- The execution order of the block is not guaranteed to match the order of items in the enumerable due to parallel execution
- All tasks complete before the method returns
- Returns self to allow chaining, like standard each

### Comparison Methods

#### <=>

Compares this Async::Enumerator with another object. Converts both to arrays for comparison.

```ruby
async_enum = [1, 2, 3].async
async_enum <=> [1, 2, 3]  # => 0
async_enum <=> [1, 2, 4]  # => -1
```

#### ==

Checks equality with another object. Converts both to arrays for comparison.

```ruby
result = [1, 2, 3].async.map { |x| x * 2 }
result == [2, 4, 6]  # => true
```

Also available as `eql?`.

## Delegated Methods

The following methods are inherently sequential and are delegated back to the wrapped enumerable for efficiency:

- `first` - Returns the first element(s)
- `take` - Takes the first n elements
- `take_while` - Takes elements while condition is true
- `lazy` - Returns a lazy enumerator
- `size` - Returns the size of the enumerable
- `length` - Alias for size

These methods bypass async processing since they don't benefit from parallelization.

## Method Chaining

Async::Enumerator supports full method chaining:

```ruby
result = [1, 2, 3, 4, 5].async
  .map { |n| fetch_data(n) }      # Parallel fetch
  .select { |data| data.valid? }   # Filter results
  .map { |data| process(data) }    # Transform data
  .sync                            # Materialize results
```

## Fiber Limits

The `max_fibers` parameter controls concurrency:

```ruby
# Default limit (from Async::Enumerable.max_fibers)
data.async.map { |x| process(x) }

# Custom limit for this instance
data.async(max_fibers: 10).map { |x| process(x) }

# Limit is preserved through chaining
enum = data.async(max_fibers: 5)
enum.map { |x| x * 2 }.select { |x| x > 10 }
# Both map and select respect the 5 fiber limit
```

## Integration with Async Runtime

Async::Enumerator requires the async runtime to be available. Operations are automatically wrapped in `Sync` blocks when needed:

```ruby
# Automatically wrapped in Sync block
result = [1, 2, 3].async.map { |n| n * 2 }

# Explicit async context
Async do
  result = urls.async.map { |url| fetch(url) }
  process_results(result)
end
```

## Performance Considerations

- Async processing has overhead - use for I/O-bound or CPU-intensive operations
- For simple transformations on small collections, synchronous processing may be faster
- Fiber limits prevent resource exhaustion with large collections
- Early termination methods (any?, all?, find) stop processing as soon as possible

## Common Patterns

### Parallel API Calls
```ruby
user_ids.async.map { |id| fetch_user(id) }
```

### Concurrent File Processing
```ruby
files.async.each { |file| process_file(file) }
```

### Batch Processing with Limits
```ruby
huge_dataset.async(max_fibers: 100).map { |item|
  expensive_operation(item)
}
```

### Pipeline Processing
```ruby
raw_data.async
  .map { |d| parse(d) }
  .select { |d| validate(d) }
  .map { |d| transform(d) }
  .sync
```