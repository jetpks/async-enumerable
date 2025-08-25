# frozen_string_literal: true

require "async/enumerable/configurable/config"

module Async
  module Enumerable
    module Configurable
      class << self
        def included(base)
          unless base.instance_variable_get(:@__async_enumerable_config_ref)
            ref = Concurrent::AtomicReference.new
            base.instance_variable_set(:@__async_enumerable_config_ref, ref)
          end
        end
      end

      # Gets config, yields a mutable version of the config to block for
      # editing if a block is given
      #
      # @yield [ConfigStruct] A mutable config containing the current values
      # @return [Config] Module configuration
      def __async_enumerable_configure
        current = __async_enumerable_config_ref.get
        return current unless block_given?

        mutable = current.to_struct
        yield mutable
        final = __async_enumerable_merge_all_config(mutable.to_h)

        current.with(**final).tap do |updated|
          @__async_enumerable_config_ref = Concurrent::AtomicReference.new(updated)
        end
      end
      alias_method :__async_enumerable_config, :__async_enumerable_configure

      def __async_enumerable_merge_all_config(config = nil)
        [Async::Enumerable.config].tap do |arr|
          class_cfg = self.class.respond_to?(:__async_enumerable_config) ? self.class.__async_enumerable_config : nil

          arr << class_cfg
          arr << @__async_enumerable_config
          arr << config
        end.compact.map(&:to_h).reduce(&:merge)
      end

      def __async_enumerable_config_ref
        if @__async_enumerable_config_ref
          @__async_enumerable_config_ref
        elsif self.class.respond_to?(:__async_enumerable_config_ref)
          self.class.__async_enumerable_config_ref
        else
          Async::Enumerable.config_ref
        end
      end
    end
  end
end
