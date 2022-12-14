# frozen_string_literal: true
require_relative 'concerns/caching'
require_relative 'descriptor'
require_relative 'has_many'
require_relative 'belongs_to'
require_relative 'has_one'
require "oj"
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

        def serializable_hash(use_cache: true)
            if use_cache && self.class.cache_enabled?
                fetch(adapter: :hash) do
                    get_hash
                end
            else
                get_hash
            end
        end
        alias to_hash serializable_hash
        alias to_h serializable_hash

        def as_json(options = nil)
            serializable_hash
        end

        def to_json(options = {}, use_cache: true)
            if use_cache && self.class.cache_enabled?
                fetch(adapter: :json) do
                    Oj.dump(get_hash, mode: :rails)
                end
            else
                Oj.dump(get_hash, mode: :rails)
            end
        end

        def get_hash
            attributes_hash.merge! associations_hash
        end

        def associations_hash
            self.class._descriptor._relationships.each_with_object({}) do |(key, relationship), hash|
                next if !relationship.should_include?(self)
                hash[key.to_s] = relationship.value(self)
            end
        end

        def attributes_hash
            self.class._descriptor._attributes.each_with_object({}) do |(key, attr), hash|
                next if !attr.should_include?(self)
                hash[key.to_s] = attr.value(self)
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