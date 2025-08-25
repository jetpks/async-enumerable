# frozen_string_literal: true

require "spec_helper"

RSpec.describe Async::Enumerable::Configurable::Config do
  describe "new" do
    it "creates a default config with DEFAULT_MAX_FIBERS" do
      config = described_class.new
      expect(config.max_fibers).to eq(described_class::DEFAULT_MAX_FIBERS)
    end
  end

  describe "#initialize" do
    it "accepts max_fibers parameter" do
      config = described_class.new(max_fibers: 100)
      expect(config.max_fibers).to eq(100)
    end

    it "uses default value when no parameters given" do
      config = described_class.new
      expect(config.max_fibers).to eq(described_class::DEFAULT_MAX_FIBERS)
    end
  end

  describe "#with" do
    it "creates a new config with updated values" do
      original = described_class.new(max_fibers: 100)
      updated = original.with(max_fibers: 200)

      expect(original.max_fibers).to eq(100)
      expect(updated.max_fibers).to eq(200)
      expect(original).not_to eq(updated)
    end
  end

  describe "immutability" do
    it "is frozen by default as a Data class" do
      config = described_class.new(max_fibers: 100)
      expect(config).to be_frozen
    end
  end

  describe "config precedence in Async::Enumerator" do
    before do
      # Reset module config to default
      config_ref = Async::Enumerable.instance_variable_get(:@config_ref)
      config_ref&.set(Async::Enumerable::Configurable::Config.new)
    end

    after do
      # Clean up - reset to default
      config_ref = Async::Enumerable.instance_variable_get(:@config_ref)
      config_ref&.set(Async::Enumerable::Configurable::Config.new)
    end

    it "uses module config as base when no config passed" do
      Async::Enumerable.configure { |c| c.max_fibers = 50 }
      enum = Async::Enumerator.new([1, 2, 3])

      expect(enum.__async_enumerable_config.max_fibers).to eq(50)
    end

    it "merges passed config over module config" do
      Async::Enumerable.configure { |c| c.max_fibers = 50 }
      passed_config = Async::Enumerable::Configurable::Config.new(max_fibers: 100)
      enum = Async::Enumerator.new([1, 2, 3], passed_config)

      expect(enum.__async_enumerable_config.max_fibers).to eq(100)
    end

    it "kwargs have highest precedence over passed config and module config" do
      Async::Enumerable.configure { |c| c.max_fibers = 50 }
      passed_config = Async::Enumerable::Configurable::Config.new(max_fibers: 100)
      enum = Async::Enumerator.new([1, 2, 3], passed_config, max_fibers: 200)

      expect(enum.__async_enumerable_config.max_fibers).to eq(200)
    end

    it "maintains backward compatibility with old max_fibers keyword arg" do
      enum = Async::Enumerator.new([1, 2, 3], max_fibers: 75)

      expect(enum.__async_enumerable_config.max_fibers).to eq(75)
    end

    # TODO: we should be testing the object identity of the config to ensure
    # it matches either the class level config, or the async::enumerable
    # module level config
    it "uses default config when nothing is specified" do
      enum = Async::Enumerator.new([1, 2, 3])

      expect(enum.__async_enumerable_config.max_fibers).to eq(
        Async::Enumerable.__async_enumerable_config.max_fibers
      )
    end

    it "passes config through transformer methods" do
      config = Async::Enumerable::Configurable::Config.new(max_fibers: 42)
      enum = Async::Enumerator.new([1, 2, 3], config)

      mapped = enum.map { |x| x * 2 }
      expect(mapped.__async_enumerable_config.max_fibers).to eq(42)

      selected = mapped.select { |x| x > 2 }
      expect(selected.__async_enumerable_config.max_fibers).to eq(42)
    end
  end
end
