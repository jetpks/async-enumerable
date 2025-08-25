# ConcurrencyBounder Module

The `ConcurrencyBounder` module provides bounded concurrency control for async operations.

## Overview

ConcurrencyBounder provides a helper method for executing async operations with a maximum fiber limit to prevent unbounded concurrency. This module is included in `Async::Enumerable` to provide a consistent way to limit the number of concurrent fibers created during async operations.

## Core Method

### with_bounded_concurrency

Executes a block with bounded concurrency using a semaphore.

This method sets up an `Async::Semaphore` to limit the number of concurrent fibers, creates a barrier under that semaphore, and yields the barrier to the block for spawning async tasks.

#### Parameters

- `early_termination` (Boolean): Whether the operation supports early termination (expects Async::Stop exceptions)
- `&block`: Block that receives the barrier for spawning tasks

#### Yields

- `barrier` (Async::Barrier): The barrier to use for spawning async tasks

#### Returns

The result of the block execution.

#### Example Usage

```ruby
def parallel_map(&block)
  results = []
  
  with_bounded_concurrency do |barrier|
    @items.each_with_index do |item, index|
      barrier.async do
        results[index] = block.call(item)
      end
    end
  end
  
  results
end
```

### max_fibers

Gets the maximum number of fibers for this instance.

#### Returns

`Integer` - The maximum number of concurrent fibers

#### Behavior

1. Returns from instance config if set
2. Falls back to class config if defined
3. Falls back to `Async::Enumerable.config.max_fibers` module default
4. Module default is 1024 if not configured

## Implementation Details

### Semaphore Usage

The module uses `Async::Semaphore` to enforce fiber limits:

```ruby
semaphore = Async::Semaphore.new(max_fibers, parent:)
barrier = Async::Barrier.new(parent: semaphore)
```

This ensures that no more than `max_fibers` tasks run concurrently.

### Early Termination Support

When `early_termination: true`:

```ruby
with_bounded_concurrency(early_termination: true) do |barrier|
  # Tasks can call barrier.stop to terminate early
  # Async::Stop exceptions are caught and handled
end
```

This is used by predicate methods like `any?` and `find` to stop processing once the result is determined.

### Normal Execution

When `early_termination: false` (default):

```ruby
with_bounded_concurrency do |barrier|
  # All tasks run to completion
  # barrier.wait blocks until all finish
end
```

## Usage in Async::Enumerable

### In Predicate Methods

```ruby
def any?(&block)
  found = Concurrent::AtomicBoolean.new(false)
  
  with_bounded_concurrency(early_termination: true) do |barrier|
    @items.each do |item|
      break if found.true?
      
      barrier.async do
        if block.call(item)
          found.make_true
          barrier.stop  # Early termination
        end
      end
    end
  end
  
  found.true?
end
```

### In Transform Methods

```ruby
def each(&block)
  with_bounded_concurrency do |barrier|
    @items.each do |item|
      barrier.async do
        block.call(item)
      end
    end
  end
end
```

## Fiber Limit Configuration

### Global Default

```ruby
Async::Enumerable.configure { |c| c.max_fibers = 100 }  # Set global default
```

### Per Instance

```ruby
class MyEnumerator
  include Async::Enumerable
  def_async_enumerable :@items, max_fibers: 50  # Class-level default
  
  def initialize(items)
    @items = items
  end
end

# Instance override
enumerator = MyEnumerator.new(items)
enumerator.async(max_fibers: 100).map { |item| process(item) }
```

### Precedence

1. Instance config (passed to `.async` method)
2. Class config (set via `def_async_enumerable`)
3. Module config (`Async::Enumerable.configure`)
4. Default constant (1024)

## Performance Considerations

### Choosing Fiber Limits

- **Too low**: Reduces parallelism, may not fully utilize resources
- **Too high**: Can cause resource exhaustion, context switching overhead
- **Recommended**: Start with defaults, tune based on workload

### Typical Values

- CPU-bound tasks: 2-4x CPU cores
- I/O-bound tasks: 50-200 fibers
- Mixed workloads: 10-50 fibers

## Thread Safety

The module operates within the async runtime which handles:
- Fiber scheduling
- Resource allocation
- Synchronization via barriers

Combined with atomic variables from concurrent-ruby, this ensures thread-safe operation.

## Error Handling

### Normal Errors

Exceptions in async tasks propagate normally:

```ruby
with_bounded_concurrency do |barrier|
  barrier.async do
    raise "Error!"  # Will propagate after barrier.wait
  end
end
```

### Early Termination

`Async::Stop` exceptions are caught when `early_termination: true`:

```ruby
with_bounded_concurrency(early_termination: true) do |barrier|
  barrier.async do
    barrier.stop  # Raises Async::Stop internally
  end
end
# Async::Stop is caught, execution continues
```

## Integration with Async Runtime

ConcurrencyBounder requires the async runtime via `Sync` blocks:

```ruby
def with_bounded_concurrency(...)
  Sync do |parent|
    # Async context established
    # Semaphore and barrier created with parent
  end
end
```

This ensures proper async context even when called from synchronous code.