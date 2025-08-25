# Benchmarking Async::Enumerable

## Running Benchmarks

```bash
# Run all benchmarks with detailed comparisons
bundle exec rake benchmark

# Run quick performance overview  
bundle exec rake benchmark_quick

# Run specific benchmark files
bundle exec benchmark-driver benchmark/size_comparison/map_100.yaml
bundle exec benchmark-driver benchmark/early_termination/any_early.yaml
```

## Benchmark Structure

The benchmarks are organized into two categories:

### Size Comparison Benchmarks (`benchmark/size_comparison/`)

Compare sync vs async performance across different collection sizes (10, 100, 1000, 10000 items):
- **map_*.yaml** - Tests parallel transformation performance at different scales

### Early Termination Benchmarks (`benchmark/early_termination/`)

Test methods that can stop processing early:
- **any_early.yaml** - Tests `any?` with early match
- **any_late.yaml** - Tests `any?` with late match  
- **find_middle.yaml** - Tests `find` with middle element match

The benchmarks simulate IO operations using scaled sleep delays to demonstrate real-world performance benefits.

## Writing Custom Benchmarks

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

Save your benchmark as a `.yaml` file and run it with:

```bash
bundle exec benchmark-driver your_benchmark.yaml
```

## Performance Tips

### Tuning max_fibers

For very large collections, limiting concurrent fibers can improve performance:

```ruby
# Default (1024 fibers max) - might create too many fibers
(1..10000).async.map { |n| process(n) }

# Limited to 100 concurrent fibers - better resource management
(1..10000).async(max_fibers: 100).map { |n| process(n) }

# Configure global default for all async operations
Async::Enumerable.configure { |c| c.max_fibers = 100 }

# Configure at class level
class DataProcessor
  include Async::Enumerable
  def_async_enumerable :@data, max_fibers: 50
end
```

### When to Adjust max_fibers

- **Large collections (1000+ items)**: Lower max_fibers to prevent resource exhaustion
- **Heavy I/O operations**: Higher max_fibers can increase throughput
- **API rate limits**: Set max_fibers to respect rate limits
- **Memory-intensive operations**: Lower max_fibers to control memory usage

## Benchmark Results Explained

The benchmark results show iterations per second (i/s) - higher is better:

- **i/s**: How many times the operation can complete per second
- **Speedup**: Ratio of async i/s to sync i/s

For example:
- Sync: 15.8 i/s = Can complete ~16 times per second
- Async: 325.2 i/s = Can complete ~325 times per second  
- Speedup: 20.6x = Async is 20.6 times faster

## Real-World Performance

In real applications, performance gains depend on:

1. **I/O wait time**: Longer waits = bigger async benefits
2. **Collection size**: More items = more parallelization opportunity
3. **Operation complexity**: Complex operations benefit more
4. **System resources**: CPU cores, memory, network bandwidth

The benchmarks use sleep to simulate I/O, but real-world gains with actual network requests, database queries, or file operations can be even more dramatic.