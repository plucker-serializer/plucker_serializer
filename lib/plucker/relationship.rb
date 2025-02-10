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

    def associated_object(serializer)
      if @block
        result = if @block.arity.zero?
                   serializer.object.instance_exec(&@block)
                 else
                   @block.call(serializer.object)
                 end
        return result if result != :nil
      end
      serializer.object.public_send(@name)
    end

    def value(serializer)
      nil
    end

    private

    def relationship_serializer(serializer, relationship_object = nil)
      if @options[:serializer].blank?
        association_class = if relationship_object.present?
                              relationship_object.class.name
                            else
                              serializer.object.class.reflect_on_association(@name.to_sym).class_name
                            end
        "#{association_class.demodulize.camelize}Serializer".constantize
      else
        @options[:serializer]
      end
    end
  end
end
