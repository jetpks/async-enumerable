# frozen_string_literal: true

module AsyncEnumerable
  module EarlyTerminable
    # Asynchronously checks if the enumerable includes the given object.
    #
    # Searches for the object in parallel across all elements. Short-circuits
    # and returns true as soon as a matching element is found.
    #
    # @param obj The object to search for
    #
    # @return [Boolean] true if the object is found, false otherwise
    #
    # @example Check for inclusion
    #   [1, 2, 3].async.include?(2)  # => true
    #   large_dataset.async.include?(target)
    #   # Searches in parallel, stops on first match
    def include?(obj)
      any? { |item| item == obj }
    end

    # Alias for #include?
    # @see #include?
    alias_method :member?, :include?
  end
end
