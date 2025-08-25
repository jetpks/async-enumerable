# frozen_string_literal: true

require "async/enumerable/methods/predicates/all"
require "async/enumerable/methods/predicates/any"
require "async/enumerable/methods/predicates/find"
require "async/enumerable/methods/predicates/find_index"
require "async/enumerable/methods/predicates/include"
require "async/enumerable/methods/predicates/none"
require "async/enumerable/methods/predicates/one"

module Async
  module Enumerable
    module Methods
      # Predicates contains async implementations of enumerable predicate methods
      # that can terminate early when their condition is met or violated.
      module Predicates
        def self.included(base)
          base.include All
          base.include Any
          base.include Find
          base.include FindIndex
          base.include Include
          base.include None
          base.include One
        end
      end
    end
  end
end
