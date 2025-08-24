# frozen_string_literal: true

require "spec_helper"

RSpec.describe "AsyncEnumerable::EarlyTerminable#lazy" do
  describe "#lazy" do
    it "returns a lazy enumerator" do
      result = [1, 2, 3].async.lazy
      expect(result).to be_a(Enumerator::Lazy)
    end

    it "delegates to the wrapped enumerable's lazy method" do
      enumerable = [1, 2, 3, 4, 5]
      async_enum = enumerable.async

      # Should return the same lazy enumerator as calling lazy on the wrapped enumerable
      async_lazy = async_enum.lazy
      regular_lazy = enumerable.lazy

      # Both should be Enumerator::Lazy
      expect(async_lazy).to be_a(Enumerator::Lazy)
      expect(regular_lazy).to be_a(Enumerator::Lazy)

      # And should produce the same results when forced
      expect(async_lazy.to_a).to eq(regular_lazy.to_a)
      expect(async_lazy.to_a).to eq([1, 2, 3, 4, 5])
    end

    it "returns the lazy enumerator from the wrapped enumerable" do
      enumerable = (1..5).to_a
      async_enum = enumerable.async

      # The lazy method should just delegate
      expect(async_enum.lazy.class).to eq(Enumerator::Lazy)

      # Basic operations should work
      result = async_enum.lazy.select { |n| n > 2 }.first(2)
      expect(result).to eq([3, 4])
    end
  end
end
