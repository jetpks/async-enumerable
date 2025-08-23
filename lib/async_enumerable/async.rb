# frozen_string_literal: true

module AsyncEnumerable
  class Async
    include Enumerable
    include Map

    def initialize(enumerable)
      @enumerable = enumerable
    end

    def each(&block)
      return @enumerable.each unless block_given?
      @enumerable.each(&block)
    end

    def to_a
      @enumerable.to_a
    end

    private

    def convert_to_original_class(result)
      case @enumerable
      when Array
        result
      when Set
        require "set"
        Set.new(result)
      when Hash
        result.to_h
      when Range
        result
      else
        result
      end
    end
  end
end
