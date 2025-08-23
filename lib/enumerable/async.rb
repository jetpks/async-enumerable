# frozen_string_literal: true

module Enumerable
  def async
    AsyncEnumerable::AsyncEnumerator.new(self)
  end
end
