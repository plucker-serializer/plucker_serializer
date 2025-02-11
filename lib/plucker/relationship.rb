# frozen_string_literal: true

require_relative 'collection'

module Plucker
  class Relationship
    attr_reader :name, :block, :options, :condition

    def initialize(name, options = {}, block)
      @name = name.to_sym
      @block = block&.freeze
      @options = options.freeze
      @condition = options[:if]&.freeze
    end

    def should_include?(serializer)
      return true unless condition

      case condition
      when Symbol then serializer.public_send(condition)
      when String then serializer.instance_eval(condition)
      when Proc
        condition.arity.zero? ? serializer.instance_exec(&condition) : serializer.instance_exec(serializer, &condition)
      else
        true
      end
    end

    def associated_object(serializer)
      if block
        result = block.arity.zero? ? serializer.object.instance_exec(&block) : block.call(serializer.object)
        return result unless result == :nil
      end

      serializer.object.public_send(name)
    end

    # This method is intended to be overridden by subclasses (such as HasOne, HasMany, etc.)
    def value(_serializer)
      nil
    end

    private

    def relationship_serializer(serializer, relationship_object = nil)
      if options[:serializer].blank?
        association_class =
          if relationship_object.present?
            relationship_object.class.name
          else
            serializer.object.class.reflect_on_association(name)&.class_name
          end
        "#{association_class.demodulize.camelize}Serializer".constantize
      else
        options[:serializer]
      end
    end
  end
end
