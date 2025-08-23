# frozen_string_literal: true

module AsyncEnumerable
  module Map
    def map(&block)
      return enum_for(__method__) unless block_given?

      result = Sync do |parent|
        barrier = ::Async::Barrier.new(parent:)
        @enumerable.each_with_index do |item, index|
          barrier.async do
            [index, block.call(item)]
          end
        end

        results = []
        barrier.wait do |task|
          index, value = task.wait
          results << [index, value]
        end

        results.sort_by(&:first).map(&:last)
      end

      convert_to_original_class(result)
    end
  end
end
