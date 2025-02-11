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

    class << self
      attr_accessor :_descriptor
    end

    self._descriptor ||= Descriptor.new(self)

    def self.inherited(base)
      super
      base._descriptor = Plucker::Descriptor.new(base)
    end

    def initialize(object, options = {})
      @object = object
    end

    def serializable_hash(use_cache: true)
      if use_cache && self.class.cache_enabled?
        fetch(adapter: :hash) { compute_hash }
      else
        compute_hash
      end
    end
    alias to_hash serializable_hash
    alias to_h serializable_hash

    def as_json(_options = nil)
      serializable_hash
    end

    def to_json(options = {}, use_cache: true)
      if use_cache && self.class.cache_enabled?
        fetch(adapter: :json) { Oj.dump(compute_hash, mode: :rails) }
      else
        Oj.dump(compute_hash, mode: :rails)
      end
    end

    private

    def compute_hash
      @compute_hash ||= attributes_hash.merge(associations_hash)
    end

    def attributes_hash
      self.class._descriptor._attributes.each_with_object({}) do |(key, attr), hash|
        hash[key] = attr.value(self) if attr.should_include?(self)
      end
    end

    def associations_hash
      self.class._descriptor._relationships.each_with_object({}) do |(key, relationship), hash|
        hash[key] = relationship.value(self) if relationship.should_include?(self)
      end
    end

    class << self
      def pluckable?
        _descriptor.pluckable?
      end

      def pluckable_columns
        _descriptor._pluckable_columns
      end

      def attributes(*attrs)
        attrs.each { |attr| attribute(attr) }
      end

      def attribute(attr, options = {}, &block)
        key       = options.fetch(:key, attr)
        attribute = Plucker::Attribute.new(attr, options, block)
        _descriptor.add_attribute(key.to_sym, attribute)
      end

      def belongs_to(attr, options = {}, &block)
        key = options.fetch(:key, attr)
        relationship = BelongsTo.new(attr, options, block)
        _descriptor.add_relationship(key.to_sym, relationship)
      end

      def has_one(attr, options = {}, &block)
        key = options.fetch(:key, attr)
        relationship = HasOne.new(attr, options, block)
        _descriptor.add_relationship(key.to_sym, relationship)
      end

      def has_many(attr, options = {}, &block)
        key = options.fetch(:key, attr)
        relationship = HasMany.new(attr, options, block)
        _descriptor.add_relationship(key.to_sym, relationship)
      end

      def model(attr)
        _descriptor.set_model(attr)
      end
    end
  end
end
