# frozen_string_literal: true

module Plucker
  class Attribute
    attr_reader :name, :block, :condition

    def initialize(name, options = {}, block)
      @name = name.to_sym
      @block = block&.freeze
      @condition = options[:if]&.freeze
    end

    def value(serializer)
      if @block
        result = if @block.arity.zero?
                   serializer.object.instance_exec(&@block)
                 else
                   @block.call(serializer.object)
                 end
        return result unless result == :nil
      end

      if serializer.respond_to?(@name)
        serializer.public_send(@name)
      else
        serializer.object.public_send(@name)
      end
    end

    def is_pluckable?
      @block.blank?
    end

    def should_include?(serializer)
      case @condition
      when nil
        true
      when Symbol
        serializer.public_send(@condition)
      when String
        serializer.instance_eval(@condition)
      when Proc
        if @condition.arity.zero?
          serializer.instance_exec(&@condition)
        else
          serializer.instance_exec(serializer, &@condition)
        end
      end
    end
  end
end
