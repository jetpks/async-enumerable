# Async::Enumerable Module

The `Async::Enumerable` module provides asynchronous, parallel execution capabilities for Ruby's Enumerable.

## Overview

This module extends Ruby's Enumerable with an `.async` method that returns an Async::Enumerator wrapper, enabling concurrent execution of enumerable operations using the socketry/async library. This allows for significant performance improvements when dealing with I/O-bound operations or processing large collections.

## Features

- Parallel execution of enumerable methods
- Thread-safe operation with atomic variables
- Optimized early-termination implementations for predicates and find operations
- Full compatibility with standard Enumerable interface
- Configurable concurrency limits to prevent unbounded fiber creation

## Basic Usage

### Including in Your Class

```ruby
class MyCollection
  include Async::Enumerable
  def_async_enumerable :@items
  
  def initialize
    @items = []
  end
  
  attr_reader :items
end

collection = MyCollection.new
collection.items.concat([1, 2, 3])
collection.async.map { |x| x * 2 }  # => [2, 4, 6]
```

### Using with Arrays and Standard Collections

```ruby
# Basic async enumeration
[1, 2, 3, 4, 5].async.map { |n| n * 2 }
# => [2, 4, 6, 8, 10] (processed in parallel)

# Async I/O operations
urls = ["http://api1.com", "http://api2.com", "http://api3.com"]
results = urls.async.map { |url| fetch_data(url) }
# All URLs fetched concurrently
```

## The def_async_enumerable Method

The `def_async_enumerable` class method defines the source of enumeration for async operations.

### Syntax

```ruby
def_async_enumerable :collection_ref, max_fibers: nil
```

### Parameters

- `collection_ref` (Symbol): The name of the method or instance variable that returns the enumerable
- `max_fibers` (Integer, optional): Default max_fibers for this class

### Examples

#### With Method

```ruby
class DataProcessor
  include Async::Enumerable
  def_async_enumerable :dataset
  
  def dataset
    fetch_data_from_source
  end
end
```

#### With Instance Variable

```ruby
class Queue
  include Async::Enumerable
  def_async_enumerable :@items  # Note the @ prefix
  
  def initialize
    @items = []
  end
end
```

#### With Custom Fiber Limit

```ruby
class LargeDataset
  include Async::Enumerable
  def_async_enumerable :@records, max_fibers: 50
  
  attr_reader :records
end
```

## Idempotent Async Chaining

The `.async` method is idempotent - calling it multiple times returns the same instance:

```ruby
arr = [1, 2, 3]
async1 = arr.async
async2 = async1.async
async3 = async2.async

async1.equal?(async2)  # => true
async2.equal?(async3)  # => true
```

This prevents unnecessary wrapper creation and allows for flexible API design.

## Fiber Limits

### Global Default

Set the global default maximum fibers:

```ruby
Async::Enumerable.configure { |c| c.max_fibers = 100 }
```

### Per-Instance

Override for specific calls:

```ruby
huge_dataset.async(max_fibers: 50).map { |item| process(item) }
```

### Default Value

The default maximum is 1024 fibers if not explicitly configured.

## Method Categories

When you include `Async::Enumerable`, you get:

### Predicate Methods (Early Termination)
- `all?`, `any?`, `none?`, `one?`
- `find`, `find_index`
- `include?`, `member?`

These methods stop processing as soon as the result is determined.

### Transformer Methods
- `map`, `select`, `reject`
- `filter_map`, `flat_map`
- `compact`, `uniq`
- `sort`, `sort_by`

These return new `Async::Enumerator` instances for chaining.

### Converter Methods
- `to_a` - Convert to array
- `sync` - Alias for `to_a`, semantically ends async chain

## Implementation Details

### Module Inclusion

When included, `Async::Enumerable` automatically:
1. Extends with `Configurable` for configuration management
2. Extends with `ClassMethods` (provides `def_async_enumerable`)
3. Includes `Comparable` for comparison operators
4. Includes all async method implementations
5. Includes `ConcurrencyBounder` for fiber limiting
6. Includes `AsyncMethod` module that provides the `async` method

### Source Resolution

The enumerable source is determined by:
1. If `def_async_enumerable` was called, uses that source
2. If source is an instance variable (starts with @), uses `instance_variable_get`
3. If source is a method name, calls that method
4. If no source defined, assumes self is enumerable

## Common Patterns

### Processing API Responses

```ruby
class ApiClient
  include Async::Enumerable
  def_async_enumerable :endpoints
  
  def endpoints
    ["users", "posts", "comments"]
  end
  
  def fetch_all
    async.map { |endpoint| fetch("/api/#{endpoint}") }
  end
end
```

### Batch Processing

```ruby
class BatchProcessor
  include Async::Enumerable
  def_async_enumerable :@items, max_fibers: 10
  
  def initialize(items)
    @items = items
  end
  
  def process_all
    async.map { |item| expensive_operation(item) }
  end
end
```

### Custom Collections

```ruby
class ThreadSafeQueue
  include Async::Enumerable
  def_async_enumerable :snapshot
  
  def initialize
    @mutex = Mutex.new
    @items = []
  end
  
  def snapshot
    @mutex.synchronize { @items.dup }
  end
  
  def add(item)
    @mutex.synchronize { @items << item }
  end
end
```

## Performance Considerations

- Async processing has overhead - best for I/O-bound or CPU-intensive operations
- Small collections with simple operations may be slower async
- Early termination methods provide significant optimization
- Fiber limits prevent resource exhaustion

## Thread Safety

All async operations use thread-safe atomic variables from concurrent-ruby:
- `Concurrent::AtomicBoolean` for boolean flags
- `Concurrent::AtomicFixnum` for counters
- `Concurrent::AtomicReference` for object references

This ensures correct behavior even with concurrent fiber execution.