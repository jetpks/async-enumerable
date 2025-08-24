# frozen_string_literal: true

# Extension to Ruby's Enumerable module that adds asynchronous capabilities.
module Enumerable
  # Returns an AsyncEnumerator wrapper that provides asynchronous versions of
  # Enumerable methods for parallel execution.
  #
  # This method enables concurrent processing of Enumerable operations using
  # the `socketry/async` library, allowing for significant performance
  # improvements when dealing with I/O-bound operations or large collections.
  #
  # @example Basic usage with async map
  #   [1, 2, 3].async.map { |n| n * 2 }  # => [2, 4, 6] (executed in parallel)
  #
  # @example Using with I/O operations
  #   urls.async.map { |url| fetch_data(url) }  # Fetches all URLs concurrently
  #
  # @example Chaining async operations
  #   data.async
  #       .select { |item| item.valid? }
  #       .map { |item| process(item) }
  #       .to_a
  #
  # @return [AsyncEnumerable::AsyncEnumerator] An async wrapper around this
  #   enumerable that provides parallel execution capabilities for enumerable
  #   methods
  #
  # @see AsyncEnumerable::AsyncEnumerator
  def async
    AsyncEnumerable::AsyncEnumerator.new(self)
  end
end
