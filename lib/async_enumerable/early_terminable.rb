# frozen_string_literal: true

module AsyncEnumerable
  # EarlyTerminable module provides optimized asynchronous implementations for
  # enumerable methods that can terminate early.
  #
  # This module includes async versions of predicate methods (all?, any?, none?, one?),
  # find operations (find, find_index, include?), and take operations (first, take,
  # take_while). These methods are optimized to stop processing as soon as the result
  # is determined, avoiding unnecessary computation.
  #
  # The implementations use atomic variables from the concurrent-ruby gem to ensure
  # thread-safe operation when multiple async tasks are running concurrently. The
  # Async::Barrier#stop method is used to cancel remaining tasks once a result is found.
  #
  # @see AsyncEnumerator
  module EarlyTerminable
    # Load all method implementations
    require_relative "early_terminable/all"
    require_relative "early_terminable/any"
    require_relative "early_terminable/none"
    require_relative "early_terminable/one"
    require_relative "early_terminable/include"
    require_relative "early_terminable/find"
    require_relative "early_terminable/find_index"
    require_relative "early_terminable/first"
    require_relative "early_terminable/take"
    require_relative "early_terminable/take_while"
    require_relative "early_terminable/lazy"
  end
end
