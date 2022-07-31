# frozen_string_literal: true
require_relative 'collection'
require_relative "field"

module Plucker
    class Relationship < Plucker::Field
        def associated_object(serializer)
            serializer.object.send(name)
        end

        def value(serializer)
            nil
        end

        private
        def relationship_serializer(serializer, relationship_object=nil)
            if self.options[:serializer].blank?
                if relationship_object.present?
                    association_class = relationship_object.class.name
                else
                    association_class = serializer.object.class.reflect_on_association(self.name.to_sym).class_name
                end
                "#{association_class.demodulize.camelize}Serializer".constantize
            else
                self.options[:serializer]
            end
        end
    end
end