# frozen_string_literal: true

require_relative 'concerns/caching'
require 'oj'
require 'pluck_all'

module Plucker
  class Collection
    include Enumerable
    include Caching

    attr_reader :objects, :cache_type, :serializer_class, :options

    def initialize(objects, options = {})
      @objects = objects
      @options = options.freeze
      @cache_type = options[:cache] == :multi ? :multi : :collection
      @serializer_class = determine_serializer_class(objects)
    end

    def serializable_hash
      unless objects.is_a?(ActiveRecord::Relation)
        return objects.map do |object|
          serializer_class.new(object).serializable_hash
        end.compact
      end

      if serializer_class.cache_enabled?
        if cache_type == :collection
          fetch(adapter: :hash) { compute_hash(use_cache: false) }
        elsif cache_type == :multi
          compute_hash(use_cache: true)
        end
      else
        compute_hash(use_cache: false)
      end
    end
    alias to_hash serializable_hash
    alias to_h serializable_hash

    def as_json(_options = nil)
      serializable_hash
    end

    def to_json(_options = {})
      if serializer_class.cache_enabled?
        if cache_type == :collection
          fetch(adapter: :json) { Oj.dump(get_collection_json(use_cache: false), mode: :rails) }
        elsif cache_type == :multi
          Oj.dump(get_collection_json(use_cache: true), mode: :rails)
        end
      else
        Oj.dump(get_collection_json(use_cache: false), mode: :rails)
      end
    end

    def cache_version
      @cache_version ||= objects.cache_version
    end

    def cache_key(adapter: :json)
      "#{objects.cache_key}/#{serializer_class._cache_digest}/#{adapter}"
    end

    private

    def get_collection_json(use_cache: false)
      if serializer_class.pluckable?
        associated_hash
      else
        objects.map { |object| Oj.load(serializer_class.new(object).to_json(use_cache: use_cache)) }
      end
    end

    def compute_hash(use_cache: false)
      if serializer_class.pluckable?
        associated_hash.map(&:symbolize_keys)
      else
        objects.map { |object| serializer_class.new(object).serializable_hash(use_cache: use_cache) }.compact
      end
    end

    def associated_hash
      objects.pluck_all(namespaced_columns)
    end

    def namespaced_columns
      @namespaced_columns ||= begin
        cols = serializer_class.pluckable_columns.to_a.map { |attr| "#{objects.model.table_name}.#{attr}" }
        cols.join(',').freeze
      end
    end

    def determine_serializer_class(objects)
      if options[:serializer].blank?
        "#{objects.klass.name.demodulize.camelize}Serializer".constantize
      else
        options[:serializer]
      end
    end
  end
end
