# frozen_string_literal: true

module Enumerable
  def async
    AsyncEnumerable::Async.new(self)
  end
end
