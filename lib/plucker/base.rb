# frozen_string_literal: true
require_relative 'concerns/caching'
require_relative 'descriptor'
require_relative 'has_many'
require_relative 'belongs_to'
require_relative 'has_one'
require 'active_support/all'

module Plucker
    class Base
        include Caching

        attr_accessor :object

        with_options instance_writer: false, instance_reader: false do |serializer|
            serializer.class_attribute :_descriptor
            self._descriptor ||= Plucker::Descriptor.new(self.class)
        end

        def self.inherited(base)
            super
            base._descriptor = Plucker::Descriptor.new(base)
        end

        def initialize(object, options = {})
            self.object = object
        end

        def serializable_hash
            if self.class.cache_enabled?
                fetch do
                    get_hash
                end
            else
                get_hash
            end
        end
        alias to_hash serializable_hash
        alias to_h serializable_hash

        def get_hash
            attributes_hash.merge! associations_hash
        end

        def as_json(options = nil)
            to_h.as_json(options)
        end

        def associations_hash
            hash = {}
            self.class._descriptor._relationships.each do |(key, relationship)|
                next if relationship.excluded?(self)
                hash[key] = relationship.value(self)
            end
            hash
        end

        def attributes_hash
            self.class._descriptor._attributes.each_with_object({}) do |(key, attr), hash|
                next if attr.excluded?(self)
                hash[key] = attr.value(self)
            end
        end

        def self.is_pluckable?
            self._descriptor.is_pluckable?
        end

        def self.pluckable_columns
            self._descriptor._pluckable_columns
        end

        def self.attributes(*attrs)
            attrs.each do |attr|
                attribute(attr)
            end
        end

        def self.attribute(attr, options = {}, &block)
            self._descriptor.add_attribute(options.fetch(:key, attr), Plucker::Attribute.new(attr, options, block))
        end

        def self.belongs_to(attr, options = {}, &block)
            self._descriptor.add_relationship(options.fetch(:key, attr), Plucker::BelongsTo.new(attr, options, block))
        end

        def self.has_one(attr, options = {}, &block)
            self._descriptor.add_relationship(options.fetch(:key, attr), Plucker::HasOne.new(attr, options, block))
        end

        def self.has_many(attr, options = {}, &block)
            self._descriptor.add_relationship(options.fetch(:key, attr), Plucker::HasMany.new(attr, options, block))
        end

        def self.model(attr)
            self._descriptor.set_model(attr)
        end
    end
end