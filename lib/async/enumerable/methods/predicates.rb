# frozen_string_literal: true

require "async/enumerable/methods/predicates/all"
require "async/enumerable/methods/predicates/any"
require "async/enumerable/methods/predicates/none"
require "async/enumerable/methods/predicates/one"
require "async/enumerable/methods/predicates/include"
require "async/enumerable/methods/predicates/find"
require "async/enumerable/methods/predicates/find_index"

module Async
  module Enumerable
    module Methods
      # Predicates contains async implementations of enumerable predicate methods
      # that can terminate early when their condition is met or violated.
      module Predicates
        include All
        include Any
        include None
        include One
        include Include
        include Find
        include FindIndex
      end
    end
  end
end
