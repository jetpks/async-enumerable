module Async
  module Enumerable
    module Comparable
      def self.included(base)
        base.include(::Comparable)
      end

      # Compares with another enumerable.
      # @param other [Object] Object to compare
      # @return [Integer, nil] Comparison result
      def <=>(other)
        return nil unless other.respond_to?(:to_a)
        to_a <=> other.to_a
      end

      # Checks equality with another enumerable.
      # @param other [Object] Object to compare
      # @return [Boolean] True if equal
      def ==(other)
        return false unless other.respond_to?(:to_a)
        to_a == other.to_a
      end
      alias_method :eql?, :==
    end
  end
end
