# Predicate Methods

Predicate methods test elements in the enumerable and return boolean values. All async predicate methods support early termination - they stop processing as soon as the result is determined.

## any?

Asynchronously checks if any element satisfies the given condition.

Executes the block for each element in parallel and returns true as soon as any element returns a truthy value. Short-circuits and stops processing remaining elements once a match is found.

### Parameters
- `pattern` (optional): Pattern to match against elements
- `&block`: Block to test each element

### Returns
`Boolean` - true if any element satisfies the condition, false otherwise

### Examples

```ruby
# Check if any number is negative
[1, 2, -3].async.any? { |n| n < 0 }  # => true (stops after -3)
[1, 2, 3].async.any? { |n| n < 0 }   # => false

# With API calls
servers.async.any? { |server| server_responding?(server) }
# Checks all servers in parallel, returns true on first response
```

### Implementation Notes
- Uses `Concurrent::AtomicBoolean` for thread-safe early termination
- Delegates pattern/no-block cases to wrapped enumerable to avoid break issues
- Stops barrier execution as soon as a match is found

## all?

Asynchronously checks if all elements satisfy the given condition.

Executes the block for each element in parallel and returns false as soon as any element returns a falsy value. Short-circuits and stops processing remaining elements once a non-match is found.

### Parameters
- `pattern` (optional): Pattern to match against elements
- `&block`: Block to test each element

### Returns
`Boolean` - true if all elements satisfy the condition, false otherwise

### Examples

```ruby
# Check if all numbers are positive
[1, 2, 3].async.all? { |n| n > 0 }  # => true
[1, -2, 3].async.all? { |n| n > 0 } # => false (stops after -2)

# With validation
forms.async.all? { |form| validate_form(form) }
# Validates all forms in parallel, returns false on first invalid
```

### Implementation Notes
- Uses `Concurrent::AtomicBoolean` to track if any element fails the test
- Delegates pattern/no-block cases to wrapped enumerable
- Stops barrier execution as soon as a non-match is found

## none?

Asynchronously checks if no elements satisfy the given condition.

Executes the block for each element in parallel and returns false as soon as any element returns a truthy value. Short-circuits and stops processing remaining elements once a match is found.

### Parameters
- `pattern` (optional): Pattern to match against elements
- `&block`: Block to test each element

### Returns
`Boolean` - true if no elements satisfy the condition, false otherwise

### Examples

```ruby
# Check if no numbers are negative
[1, 2, 3].async.none? { |n| n < 0 }  # => true
[1, -2, 3].async.none? { |n| n < 0 } # => false (stops after -2)

# With validation
errors.async.none? { |error| error.critical? }
# Checks all errors in parallel, returns false on first critical
```

### Implementation Notes
- Uses `Concurrent::AtomicBoolean` to track if any element matches
- Essentially the inverse of `any?`
- Delegates pattern/no-block cases to wrapped enumerable

## one?

Asynchronously checks if exactly one element satisfies the given condition.

Executes the block for each element in parallel and returns true if exactly one element returns a truthy value. Short-circuits and returns false as soon as a second match is found.

### Parameters
- `pattern` (optional): Pattern to match against elements
- `&block`: Block to test each element

### Returns
`Boolean` - true if exactly one element satisfies the condition

### Examples

```ruby
# Check for single admin
users.async.one? { |u| u.admin? }  # => true if exactly one admin

# With validation
configs.async.one? { |c| c.primary? }
# Validates all configs in parallel, ensures only one is primary
```

### Implementation Notes
- Uses `Concurrent::AtomicFixnum` to count matches
- Stops barrier execution when count exceeds 1
- Delegates pattern/no-block cases to wrapped enumerable

## find / detect

Asynchronously finds the first element that satisfies the given condition.

Executes the block for each element in parallel and returns the first element that matches. Uses thread-safe synchronization to ensure that the "first" element returned is the first in enumeration order, not just the first to complete.

### Parameters
- `ifnone` (optional): Proc to call if no element is found
- `&block`: Block to test each element

### Returns
The first matching element, or nil/ifnone result if not found

### Examples

```ruby
# Find first prime number
numbers.async.find { |n| prime?(n) }

# With fallback
users.async.find(-> { User.new }) { |u| u.admin? }
# Returns new User if no admin found

# With expensive checks
documents.async.find { |doc| analyze_content(doc).contains_keyword? }
# Analyzes all documents in parallel, returns first match
```

### Implementation Notes
- Uses `Concurrent::AtomicReference` to track first match by index
- Maintains enumeration order despite parallel execution
- Supports `ifnone` proc for custom fallback behavior

## find_index

Asynchronously finds the index of the first element that satisfies the given condition.

Executes the block for each element in parallel and returns the index of the first element that matches. Ensures the returned index is the first in enumeration order.

### Parameters
- `value` (optional): Value to find the index of
- `&block`: Block to test each element

### Returns
`Integer` or `nil` - Index of first matching element, or nil if not found

### Examples

```ruby
# Find index of first large file
files.async.find_index { |f| f.size > 1_000_000 }

# Find specific value
items.async.find_index("target")

# With validation
results.async.find_index { |r| r.status == :success }
```

### Implementation Notes
- Uses `Concurrent::AtomicFixnum` to track minimum index
- Handles both value-based and block-based searches
- Maintains enumeration order despite parallel execution

## include? / member?

Asynchronously checks if the enumerable includes a given value.

Checks all elements in parallel for equality with the given value. Short-circuits and returns true as soon as a match is found.

### Parameters
- `obj`: Object to search for

### Returns
`Boolean` - true if the enumerable includes the object

### Examples

```ruby
# Check for value
[1, 2, 3].async.include?(2)  # => true

# With objects
users.async.include?(target_user)

# Complex equality
configs.async.include?(production_config)
```

### Implementation Notes
- Uses `Concurrent::AtomicBoolean` for thread-safe early termination
- Relies on the object's `==` method for comparison
- Short-circuits on first match

## Pattern Matching Support

When called with a pattern argument instead of a block, predicate methods delegate to the wrapped enumerable's synchronous implementation. This ensures correct behavior with Ruby's pattern matching:

```ruby
# Pattern matching
[1, 2, 3].async.any?(Integer)     # => true
[:a, :b].async.all?(Symbol)       # => true
[1, 2, 3].async.none?(String)     # => true
[1, 2, 3].async.one?(2)           # => true
```

## No-Block Behavior

When called without a block or pattern, predicate methods check for truthiness:

```ruby
[nil, false, 1].async.any?        # => true (1 is truthy)
[1, 2, 3].async.all?              # => true (all truthy)
[nil, false].async.none?          # => true (none truthy)
[nil, false, 1].async.one?        # => true (exactly one truthy)
```

## Performance Considerations

- All predicate methods use early termination to minimize unnecessary work
- Thread-safe atomic variables prevent race conditions
- Barrier stops immediately when result is determined
- Pattern/no-block cases delegate to avoid async overhead when not needed