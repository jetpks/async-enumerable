# Converter Methods

Converter methods transform async enumerables into other data types, typically arrays.

## to_a

Converts the wrapped enumerable to an array.

This method simply converts the wrapped enumerable to an array without any async processing. Note that async operations like map and select already return arrays internally.

### Returns
`Array` - The wrapped enumerable converted to an array

### Examples

```ruby
# Basic conversion
async_enum = (1..3).async
async_enum.to_a  # => [1, 2, 3]

# Converting a Set
async_set = Set[1, 2, 3].async
async_set.to_a  # => [1, 2, 3] (order may vary)

# After transformations
[1, 2, 3].async.map { |n| n * 2 }.to_a  # => [2, 4, 6]
```

### Implementation Notes
- Uses `enumerable_source` to get the appropriate source
- Handles self-referential sources to avoid infinite recursion
- Delegates to the source's `to_a` method

## sync

Synchronizes the async enumerable back to a regular array. This is an alias for `to_a` that provides a more semantic way to end an async chain and get the results.

### Returns
`Array` - The wrapped enumerable converted to an array

### Examples

```ruby
# Chaining with sync
result = [:foo, :bar].async
                     .map { |sym| fetch_data(sym) }
                     .sync
# => [<data for :foo>, <data for :bar>]

# Alternative to to_a
data.async.select { |x| x.valid? }.sync  # same as .to_a

# Complete async pipeline
[1, 2, 3, 4, 5].async
  .map { |n| expensive_operation(n) }
  .select { |result| result.success? }
  .map { |result| result.value }
  .sync  # Materializes final results
```

### Why Use sync?

The `sync` method provides semantic clarity:
- `to_a` implies conversion to array format
- `sync` implies waiting for async operations to complete and collecting results
- Both do the same thing, but `sync` better expresses intent in async contexts

## Usage Patterns

### Basic Conversion
```ruby
# Simple enumerable to array
(1..5).async.to_a  # => [1, 2, 3, 4, 5]
```

### After Async Operations
```ruby
# Process data asynchronously, then collect results
urls.async
  .map { |url| fetch_data(url) }
  .select { |data| data.valid? }
  .sync  # Get final array of valid data
```

### With Custom Enumerables
```ruby
class MyCollection
  include Enumerable
  def each
    yield 1
    yield 2
    yield 3
  end
end

MyCollection.new.async.to_a  # => [1, 2, 3]
```