# Technical Details

## Module Architecture

Async::Enumerable is organized into logical modules for better maintainability and selective inclusion:

### Core Modules

- **`Async::Enumerable`** - Main module that ties everything together
- **`Async::Enumerator`** - Wrapper class that provides async enumeration

### Method Modules

- **`Async::Enumerable::Methods::Transformers`** - Methods that transform collections
  - `map`, `select`, `reject`, `filter_map`, `flat_map`, `compact`, `uniq`, `sort`, `sort_by`
  
- **`Async::Enumerable::Methods::Predicates`** - Methods that test conditions with early termination
  - `all?`, `any?`, `none?`, `one?`, `include?`, `find`, `find_index`
  
- **`Async::Enumerable::Methods::Converters`** - Methods that convert to other types
  - `to_a`, `sync`
  
- **`Async::Enumerable::Methods::Aggregators`** - Aggregation methods inherited from Enumerable
  - `reduce`, `sum`, `count`, `min`, `max`, `minmax`, `group_by`, `tally`
  
- **`Async::Enumerable::Methods::Iterators`** - Iteration helpers inherited from Enumerable
  - `each_with_index`, `each_cons`, `each_slice`, `with_index`, `cycle`
  
- **`Async::Enumerable::Methods::Slicers`** - Slicing/filtering methods
  - `drop`, `take`, `grep`, `partition`, `chunk`, `slice_before`, `slice_after`

### Support Modules

- **`Async::Enumerable::ConcurrencyBounder`** - Controls concurrent fiber limits
- **`Async::Enumerable::Configurable`** - Configuration management with hierarchical inheritance
- **`Async::Enumerable::Comparable`** - Comparison operators for async enumerators

## Selective Module Inclusion

You can include specific modules for custom implementations:

```ruby
class CustomAsync
  include Enumerable
  
  # Include only what you need
  include Async::Enumerable::Methods::Transformers::Map
  include Async::Enumerable::Methods::Predicates::Any
  include Async::Enumerable::Methods::Converters::Sync
  include Async::Enumerable::ConcurrencyBounder
  
  # Now you have just map, any?, and sync with concurrency control
end
```

## Configuration System

### Configuration Hierarchy

Configuration follows a three-level hierarchy (most specific wins):

1. **Instance level** - Configuration for a specific async enumerator instance
2. **Class level** - Configuration for all instances of a class
3. **Module level** - Global defaults for all async enumerables

```ruby
# Module level (global default)
Async::Enumerable.configure do |config|
  config.max_fibers = 100
end

# Class level (overrides module default)
class DataProcessor
  include Async::Enumerable
  def_async_enumerable :@data, max_fibers: 50
end

# Instance level (overrides class default)
processor.async(max_fibers: 25).map { |x| process(x) }
```

### Configuration Options

- **`max_fibers`** - Maximum number of concurrent fibers (default: 1024)
- **`collection_ref`** - Symbol or instance variable name for the collection source

## Implementation Details

### Async Execution Pattern

Methods follow this general pattern:

1. Wrap execution in a `Sync` block to enter async context
2. Create an `Async::Barrier` for task coordination
3. Spawn async tasks for each element
4. Wait for barrier completion
5. Return results

```ruby
def async_map(&block)
  Sync do
    results = []
    barrier = Async::Barrier.new
    
    collection.each_with_index do |item, index|
      barrier.async do
        results[index] = block.call(item)
      end
    end
    
    barrier.wait
    results
  end
end
```

### Early Termination Pattern

Predicates use atomic variables for thread-safe early termination:

```ruby
def async_any?(&block)
  found = Concurrent::AtomicBoolean.new(false)
  
  Sync do
    barrier = Async::Barrier.new
    
    collection.each do |item|
      break if found.true?
      
      barrier.async do
        if block.call(item)
          found.make_true
          barrier.stop  # Stop all other tasks
        end
      end
    end
    
    barrier.wait
  end
  
  found.true?
end
```

### Thread Safety

The gem uses `concurrent-ruby` for thread-safe operations:

- `Concurrent::AtomicBoolean` - Thread-safe boolean flags
- `Concurrent::AtomicFixnum` - Thread-safe counters
- `Concurrent::AtomicReference` - Thread-safe configuration storage

## Method Behavior Notes

### Methods That Maintain Order

These methods preserve element order despite parallel execution:
- `map`, `collect`, `filter_map`
- `sort`, `sort_by`
- `to_a`, `entries`

### Methods That Don't Guarantee Order

These return the fastest result, not necessarily the first:
- `find`, `detect`
- `find_index`

### Sequential Methods

These are delegated to synchronous implementation:
- `first`, `take`, `take_while`
- `lazy` (incompatible with async's barrier pattern)

## Performance Considerations

### Fiber Overhead

Each async operation spawns fibers, which have overhead:
- Memory: ~4KB per fiber
- Context switching: ~1-2 microseconds
- Creation/teardown: ~5-10 microseconds

For very fast operations (< 10 microseconds), sync may be faster.

### Optimal Use Cases

Async enumerable shines when:
- Operations take > 1 millisecond
- I/O wait time dominates processing time
- Collection size is 10-10,000 items
- Operations are independent

### Anti-Patterns to Avoid

```ruby
# BAD: Shared mutable state
sum = 0
items.async.each { |x| sum += x }  # Race condition!

# GOOD: Use reduce instead
sum = items.async.reduce(0) { |s, x| s + x }

# BAD: Sequential dependencies  
results = []
items.async.each { |x| results << process(results.last, x) }

# GOOD: Use synchronous for sequential operations
results = []
items.each { |x| results << process(results.last, x) }
```