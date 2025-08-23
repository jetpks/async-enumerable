# frozen_string_literal: true

module AsyncEnumerable
  class AsyncEnumerator
    include Enumerable
    include Each
    include ShortCircuit

    def initialize(enumerable)
      @enumerable = enumerable
    end

    def to_a
      @enumerable.to_a
    end
  end
end
