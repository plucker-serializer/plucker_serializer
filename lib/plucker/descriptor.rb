# frozen_string_literal: true

module Plucker
  class Descriptor
    attr_accessor :_serialized_model, :_attributes, :_relationships, :_pluckable_columns, :_pluckable

    def initialize(serializer_class)
      self._serialized_model = get_serialized_model(serializer_class)
      self._attributes = {}
      self._relationships = {}
      self._pluckable_columns = Set.new
      self._pluckable = true
    end

    def pluckable?
      _pluckable
    end

    def add_attribute(key, attr)
      _attributes[key] = attr
      if attr.pluckable? && _serialized_model&.column_names&.include?(attr.name.to_s)
        _pluckable_columns << attr.name
      else
        self._pluckable = false
      end
    end

    def add_relationship(key, relationship)
      _relationships[key] = relationship
      self._pluckable = false
    end

    def set_model(model)
      self._serialized_model = model
    end

    def get_serialized_model(serializer_class)
      serializer_class.name.split(/Serializer/).first.constantize
    rescue NameError, LoadError
      nil
    end
  end
end
