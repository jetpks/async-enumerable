# frozen_string_literal: true

module AsyncEnumerable
  module Each
    def each(&block)
      return enum_for(__method__) unless block_given?

      Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)

        @enumerable.each do |item|
          barrier.async do
            block.call(item)
          end
        end

        barrier.wait
      end

      # Return self to allow chaining, like standard each
      self
    end
  end
end
