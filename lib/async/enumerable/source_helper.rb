# frozen_string_literal: true

module Async
  module Enumerable
    # Provides a helper method to get the enumerable source
    # for both wrapper pattern (Async::Enumerator) and includable pattern
    module SourceHelper
      private

      # Gets the enumerable source based on the context:
      # - For Async::Enumerator: returns the instance variable @enumerable
      # - For includable pattern with def_enumerator: calls the configured method
      # - For includable pattern without def_enumerator: returns self
      def enumerable_source
        if self.class.respond_to?(:enumerable_source) && self.class.enumerable_source
          source = self.class.enumerable_source
          # Check if it's an instance variable (starts with @)
          if source.is_a?(Symbol) && source.to_s.start_with?("@")
            instance_variable_get(source)
          else
            send(source)
          end
        else
          # Includable pattern without def_enumerator, assume self is enumerable
          self
        end
      end
    end
  end
end
