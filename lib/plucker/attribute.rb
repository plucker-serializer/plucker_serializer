# frozen_string_literal: true
module Plucker
    class Attribute
        attr_reader :name, :block, :condition
       
        def initialize(name, options = {}, block)
            @name = name
            @block = block
            @condition = options[:if]
        end

        def value(serializer)
            block_value = instance_exec(serializer.object, &@block) if @block
            if @block && block_value != :nil
                block_value
            else
                if serializer.respond_to?(@name)
                    serializer.send(@name)
                else
                    serializer.object.send(@name)
                end
            end
        end

        def is_pluckable?
            @block.blank?
        end

        def excluded?(record)
            case @condition
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
    end
end