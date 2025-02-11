# frozen_string_literal: true

module Plucker
  class Descriptor
    attr_accessor :_serialized_model, :_attributes, :_relationships, :_pluckable_columns, :_pluckable

    def initialize(serializer_class)
      @_serialized_model  = get_serialized_model(serializer_class)
      @_attributes        = {}
      @_relationships     = {}
      @_pluckable_columns = Set.new
      @_pluckable         = true
    end

    def pluckable?
      @_pluckable
    end

    def add_attribute(key, attr)
      @_attributes[key] = attr

      if attr.pluckable? && @_serialized_model&.column_names&.include?(attr.name.to_s)
        @_pluckable_columns << attr.name
      else
        @_pluckable = false
      end
    end

    def add_relationship(key, relationship)
      @_relationships[key] = relationship
      @_pluckable = false
    end

    def set_model(model)
      @_serialized_model = model
    end

    def get_serialized_model(serializer_class)
      model_name = serializer_class.name.split(/Serializer/).first.freeze
      model_name.constantize
    rescue NameError, LoadError
      nil
    end
  end
end
