# frozen_string_literal: true
require_relative 'concerns/caching'
require "oj"
require "pluck_all"

module Plucker
  class Collection
    include Enumerable
    include Caching

    attr_reader :objects, :cache_type, :serializer_class, :options

    def initialize(objects, options = {})
      @objects = objects
      @options = options
      @cache_type = options[:cache] == :multi ? :multi : :collection
      @serializer_class = get_serialized_model(objects)
    end

    def serializable_hash
      if (not objects.is_a?(ActiveRecord::Relation))
        objects.map do |object|
          serializer_class.new(object).serializable_hash
        end.compact
      else
        if serializer_class.cache_enabled?
          if @cache_type == :collection
            fetch(adapter: :hash) do
              get_hash(use_cache: false)
            end
          elsif @cache_type == :multi
            get_hash(use_cache: true)
          end
        else
          get_hash(use_cache: false)
        end
      end
    end
    alias to_hash serializable_hash
    alias to_h serializable_hash

    def as_json(options = nil)
      serializable_hash
    end

    def to_json(options = {})
      if serializer_class.cache_enabled?
        if @cache_type == :collection
          fetch(adapter: :json) do
            Oj.dump(get_collection_json(use_cache: false), mode: :rails)
          end
        elsif @cache_type == :multi
          Oj.dump(get_collection_json(use_cache: true), mode: :rails)
        end
      else
        Oj.dump(get_collection_json(use_cache: false), mode: :rails)
      end
    end

    def get_collection_json(use_cache: false)
      if serializer_class.is_pluckable?
        associated_hash
      else
        objects.map do |object|
          Oj.load(serializer_class.new(object).to_json(use_cache: use_cache))
        end
      end
    end

    def get_hash(use_cache: false)
      if serializer_class.is_pluckable?
        associated_hash
      else
        objects.map do |object|
          serializer_class.new(object).serializable_hash(use_cache: use_cache)
        end.compact
      end
    end

    def cache_version
      return @cache_version if defined?(@cache_version)
      @cache_version = objects.cache_version
    end

    def cache_key(adapter: :json)
      objects.cache_key + '/' + serializer_class._cache_digest + "/" + adapter.to_s
    end

    private
    def associated_hash
      pluck_to_hash(objects, serializer_class.pluckable_columns.to_a)
    end

    def pluck_to_hash(objects, attrs)
      namespaced_attrs = attrs.map { |attr| objects.model.table_name.to_s + "." + attr.to_s }
      objects.pluck_all(namespaced_attrs.join(','))
    end

    def get_serialized_model(objects)
      if options[:serializer].blank?
        "#{objects.klass.name.demodulize.camelize}Serializer".constantize
      else
        options[:serializer]
      end
    end
  end
end