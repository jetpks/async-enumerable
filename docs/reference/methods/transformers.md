# Transformer Methods

Transformer methods create modified collections from the original enumerable. All transformer methods return an `Async::Enumerator` for chaining operations.

## Overview

Transformer methods delegate to the standard Enumerable implementation but wrap the result in a new `Async::Enumerator` to enable continued chaining. The actual transformation happens through the parent Enumerable module.

## Available Methods

### map / collect

Transforms each element using the given block.

```ruby
[1, 2, 3].async.map { |n| n * 2 }  # => Async::Enumerator([2, 4, 6])
```

### select / filter / find_all

Selects elements for which the block returns true.

```ruby
[1, 2, 3, 4].async.select { |n| n.even? }  # => Async::Enumerator([2, 4])
```

### reject

Rejects elements for which the block returns true.

```ruby
[1, 2, 3, 4].async.reject { |n| n.even? }  # => Async::Enumerator([1, 3])
```

### filter_map

Maps and filters in a single pass, removing nil values.

```ruby
[1, 2, 3, 4].async.filter_map { |n| n * 2 if n.even? }  # => Async::Enumerator([4, 8])
```

### flat_map / collect_concat

Maps and flattens the result by one level.

```ruby
[[1, 2], [3, 4]].async.flat_map { |arr| arr.map { |n| n * 2 } }
# => Async::Enumerator([2, 4, 6, 8])
```

### compact

Removes nil elements.

```ruby
[1, nil, 2, nil, 3].async.compact  # => Async::Enumerator([1, 2, 3])
```

### uniq

Removes duplicate elements.

```ruby
[1, 1, 2, 2, 3].async.uniq  # => Async::Enumerator([1, 2, 3])
```

### sort

Sorts elements using their natural ordering or a provided comparison.

```ruby
[3, 1, 2].async.sort  # => Async::Enumerator([1, 2, 3])
[3, 1, 2].async.sort { |a, b| b <=> a }  # => Async::Enumerator([3, 2, 1])
```

### sort_by

Sorts elements by the result of the given block.

```ruby
users.async.sort_by { |u| u.age }  # Sorts users by age
files.async.sort_by { |f| f.size }  # Sorts files by size
```

## Chaining

All transformer methods return an `Async::Enumerator`, enabling method chaining:

```ruby
result = [1, 2, 3, 4, 5].async
  .map { |n| n * 2 }        # [2, 4, 6, 8, 10]
  .select { |n| n > 4 }      # [6, 8, 10]
  .map { |n| n + 1 }         # [7, 9, 11]
  .sort { |a, b| b <=> a }   # [11, 9, 7]
  .sync                      # Materializes the result
```

## Implementation Notes

- Transformer methods leverage the standard Enumerable module for transformation logic
- Each method wraps the result in a new `Async::Enumerator` with the same fiber limit
- Methods returning enumerators without blocks are handled correctly
- The `max_fibers` setting is preserved through the transformation chain