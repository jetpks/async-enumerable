# frozen_string_literal: true

module Async
  module Enumerable
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
      require "async/enumerable/early_terminable/all"
      require "async/enumerable/early_terminable/any"
      require "async/enumerable/early_terminable/find"
      require "async/enumerable/early_terminable/find_index"
      require "async/enumerable/early_terminable/first"
      require "async/enumerable/early_terminable/include"
      require "async/enumerable/early_terminable/lazy"
      require "async/enumerable/early_terminable/none"
      require "async/enumerable/early_terminable/one"
      require "async/enumerable/early_terminable/take"
      require "async/enumerable/early_terminable/take_while"
    end
  end
end
