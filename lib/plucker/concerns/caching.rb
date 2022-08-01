# frozen_string_literal: true
require 'active_support/all'

module Plucker
  module Caching
    extend ActiveSupport::Concern

    included do
      with_options instance_writer: false, instance_reader: false do |serializer|
        serializer.class_attribute :_cache
        serializer.class_attribute :_cache_options
        serializer.class_attribute :_cache_store
      end
    end

    module ClassMethods
      def _cache_digest
        return @_cache_digest if defined?(@_cache_digest)
        @_cache_digest = Digest::SHA1.hexdigest(self.name)
      end

      def cache(options = {})
        self._cache = true
        self._cache_store = Plucker.config.cache_store || ActiveSupport::Cache.lookup_store(:null_store)
        self._cache_options = options.blank? ? {} : options
      end

      def cache_enabled?
        self._cache_store.present? && _cache.present?
      end
    end

    def fetch
      if serializer_class.cache_enabled?
        serializer_class._cache_store.fetch(cache_key, version: cache_version, options: serializer_class._cache_options) do
          yield
        end
      else
        yield
      end
    end

    def cache_version
      return @cache_version if defined?(@cache_version)
      @cache_version = object.cache_version
    end

    def cache_key
      return @cache_key if defined?(@cache_key)
      @cache_key = object.cache_key + "/" + serializer_class._cache_digest
    end

    def serializer_class
      @serializer_class ||= self.class
    end
  end
end