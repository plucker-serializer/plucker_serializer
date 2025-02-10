# frozen_string_literal: true

require_relative 'concerns/caching'
require_relative 'descriptor'
require_relative 'has_many'
require_relative 'belongs_to'
require_relative 'has_one'
require 'oj'
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
        next unless relationship.should_include?(self)

        hash[key.to_sym] = relationship.value(self)
      end
    end

    def attributes_hash
      self.class._descriptor._attributes.each_with_object({}) do |(key, attr), hash|
        next unless attr.should_include?(self)

        hash[key.to_sym] = attr.value(self)
      end
    end

    def self.pluckable?
      self._descriptor.pluckable?
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
      key = options.fetch(:key, attr)
      attribute = Plucker::Attribute.new(attr, options, block)
      self._descriptor.add_attribute(key.to_sym, attribute)
    end

    def self.belongs_to(attr, options = {}, &block)
      key = options.fetch(:key, attr)
      belongs_to = Plucker::BelongsTo.new(attr, options, block)
      self._descriptor.add_relationship(key.to_sym, belongs_to)
    end

    def self.has_one(attr, options = {}, &block)
      key = options.fetch(:key, attr)
      has_one = Plucker::HasOne.new(attr, options, block)
      self._descriptor.add_relationship(key.to_sym, has_one)
    end

    def self.has_many(attr, options = {}, &block)
      key = options.fetch(:key, attr)
      has_many = Plucker::HasMany.new(attr, options, block)
      self._descriptor.add_relationship(key.to_sym, has_many)
    end

    def self.model(attr)
      self._descriptor.set_model(attr)
    end
  end
end
