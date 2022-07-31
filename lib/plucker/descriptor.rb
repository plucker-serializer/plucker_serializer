# frozen_string_literal: true
module Plucker
    class Descriptor
        attr_accessor :_serialized_model, :_attributes, :_relationships, :_pluckable_columns, :_is_pluckable

        def initialize(serializer_class)
            self._serialized_model = get_serialized_model(serializer_class)
            self._attributes = {}
            self._relationships = {}
            self._pluckable_columns = Set.new([:updated_at])
            self._is_pluckable = true
        end

        def is_pluckable?
            self._is_pluckable && !self._relationships.present?
        end

        def add_attribute(key, attr)
            self._attributes[key] = attr
            if attr.is_pluckable? && self._serialized_model && self._serialized_model.column_names.include?(attr.name.to_s)
                self._pluckable_columns << attr.name
            else
                self._is_pluckable = false
            end
        end

        def add_relationship(key, relationship)
            self._relationships[key] = relationship
            self._is_pluckable = false
        end

        def set_model(model)
            self._serialized_model = model
        end

        def get_serialized_model(serializer_class)
            begin
                serializer_class.name.split(/Serializer/).first.constantize
            rescue NameError, LoadError => e
                nil
            end
        end
    end
end