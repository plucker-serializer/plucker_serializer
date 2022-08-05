# frozen_string_literal: true
require_relative 'collection'

module Plucker
    class Relationship
        attr_reader :name, :block, :options, :condition
       
        def initialize(name, options = {}, block)
            @name = name
            @block = block
            @options = options
            @condition = options[:if]
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
            else
                nil
            end
        end

        def associated_object(serializer)
            block_value = instance_exec(serializer.object, &@block) if @block
            if @block && block_value != :nil
                block_value
            else
                serializer.object.send(@name)
            end
        end

        def value(serializer)
            nil
        end

        private
        def relationship_serializer(serializer, relationship_object=nil)
            if @options[:serializer].blank?
                if relationship_object.present?
                    association_class = relationship_object.class.name
                else
                    association_class = serializer.object.class.reflect_on_association(@name.to_sym).class_name
                end
                "#{association_class.demodulize.camelize}Serializer".constantize
            else
                @options[:serializer]
            end
        end
    end
end