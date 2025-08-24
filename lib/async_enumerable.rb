# frozen_string_literal: true

require "async"
require "async/barrier"
require "concurrent"

# AsyncEnumerable provides asynchronous, parallel execution capabilities for
# Ruby's Enumerable.
#
# This gem extends Ruby's Enumerable module with an `.async` method that
# returns an AsyncEnumerator wrapper, enabling concurrent execution of
# enumerable operations using the socketry/async library. This allows for
# significant performance improvements when dealing with I/O-bound operations
# or processing large collections.
#
# ## Features
#
# - Parallel execution of enumerable methods
# - Thread-safe operation with atomic variables
# - Optimized early-termination implementations for predicates and find
#   operations
# - Full compatibility with standard Enumerable interface
#
# ## Usage
#
# @example Basic async enumeration
#   [1, 2, 3, 4, 5].async.map { |n| n * 2 }
#   # => [2, 4, 6, 8, 10] (processed in parallel)
#
# @example Async I/O operations
#   urls = ["http://api1.com", "http://api2.com", "http://api3.com"]
#   results = urls.async.map { |url| fetch_data(url) }
#   # All URLs fetched concurrently
#
# @example Early termination optimization
#   large_array.async.any? { |item| expensive_check(item) }
#   # Stops as soon as one item returns true
#
# @example Chaining async operations
#   data.async
#       .select { |item| item.active? }
#       .map { |item| transform(item) }
#       .reject { |item| item.invalid? }
#       .to_a
#
# @see Enumerable#async
# @see AsyncEnumerable::AsyncEnumerator
module AsyncEnumerable; end

require "async_enumerable/version"
require "async_enumerable/early_terminable"
require "async_enumerable/async"

require "enumerable/async"
