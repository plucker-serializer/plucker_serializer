# frozen_string_literal: true
module Plucker
    Field = Struct.new(:name, :options, :block) do
        def initialize(*)
            super
            validate_condition!
        end

        def value(serializer)
            block_value = instance_exec(serializer.object, &block) if block
            if block && block_value != :nil
                block_value
            else
                if serializer.respond_to?(name)
                    serializer.send(name)
                else
                    serializer.object.send(name)
                end
            end
        end

        def is_pluckable?
            block.blank?
        end

        def excluded?(serializer)
            case condition_type
            when :if
                !evaluate_condition(serializer)
            when :unless
                evaluate_condition(serializer)
            else
                false
            end
        end

        private
        def validate_condition!
            return if condition_type == :none

            case condition
            when Symbol, String, Proc
                # noop
            else
                fail TypeError, "#{condition_type.inspect} should be a Symbol, String or Proc"
            end
        end

        def evaluate_condition(serializer)
            case condition
            when Symbol
                serializer.public_send(condition)
            when String
                serializer.instance_eval(condition)
            when Proc
                if condition.arity.zero?
                    serializer.instance_exec(&condition)
                else
                    serializer.instance_exec(serializer, &condition)
                end
            else
                nil
            end
        end

        def condition_type
            @condition_type ||=
                if options.key?(:if)
                    :if
                elsif options.key?(:unless)
                    :unless
                else
                    :none
                end
        end

        def condition
            options[condition_type]
        end
    end
end