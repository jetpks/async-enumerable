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
      # Try to preserve the original enumerable's class
      original_class = @enumerable.class

      # If it's already an Array and the original was too, just return it
      return result if result.instance_of?(original_class)

      # Special handling for Hash - when mapping over a hash, result is array of pairs
      if original_class == Hash && result.all? { |item| item.is_a?(Array) && item.size == 2 }
        return result.to_h
      end

      # Try to create a new instance of the original class
      # First, try calling new with the result array
      if original_class.respond_to?(:new)
        begin
          return original_class.new(result)
        rescue ArgumentError, TypeError
          # Some classes might not accept an array in new()
          # Try with no args and see if we can use replace or similar
          begin
            instance = original_class.new
            if instance.respond_to?(:replace)
              instance.replace(result)
              return instance
            end
          rescue ArgumentError, TypeError
            # Can't instantiate with no args either
          end
        end
      end

      # Default: return as array (many Enumerable methods return arrays anyway)
      result
    end
  end
end
