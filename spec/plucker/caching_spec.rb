# frozen_string_literal: true

require 'spec_helper'
require 'active_record/connection_adapters/postgresql_adapter'

describe Plucker::Caching do
  class InspectableMemoryStore < ActiveSupport::Cache::MemoryStore
    def keys
      @data.keys
    end
  end

  context 'single object caching' do
    it 'no caching if option not passed' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooNoCacheSerializer < Plucker::Base
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      cache_key = foo.cache_key + '/' + Digest::SHA1.hexdigest('FooNoCacheSerializer') + '/json'
      expect(memory_store.keys.size).to eq(0)

      serializer_instance = FooNoCacheSerializer.new(foo)
      expect(FooNoCacheSerializer.cache_enabled?).to eq(false)
      expect(serializer_instance.to_h).to eq({ name: foo.name, address: foo.address })

      expect(serializer_instance.cache_key).to eq(cache_key)
      expect(memory_store.exist?(cache_key)).to be(false)
    end

    it 'cache hash' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooMemoryCacheSerializer < Plucker::Base
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      cache_key = foo.cache_key + '/' + Digest::SHA1.hexdigest('FooMemoryCacheSerializer') + '/hash'
      expected_result = { name: foo.name, address: foo.address }
      expect(memory_store.keys.size).to eq(0)

      serializer_instance = FooMemoryCacheSerializer.new(foo)
      expect(FooMemoryCacheSerializer.cache_enabled?).to eq(true)
      expect(serializer_instance.to_h).to eq(expected_result)

      expect(serializer_instance.cache_key(adapter: :hash)).to eq(cache_key)
      expect(memory_store.read(cache_key)).to eq(expected_result)
    end

    it 'caches json' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooMemoryCacheSerializer < Plucker::Base
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      cache_key = foo.cache_key + '/' + Digest::SHA1.hexdigest('FooMemoryCacheSerializer') + '/json'
      expected_result = { name: foo.name, address: foo.address }.to_json
      expect(memory_store.keys.size).to eq(0)

      serializer_instance = FooMemoryCacheSerializer.new(foo)
      expect(FooMemoryCacheSerializer.cache_enabled?).to eq(true)
      expect(serializer_instance.to_json).to eq(expected_result)

      expect(serializer_instance.cache_key(adapter: :json)).to eq(cache_key)
      expect(memory_store.read(cache_key)).to eq(expected_result)
    end
  end

  context 'collection caching' do
    it 'no caching if option not passed in serializer' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooNoCacheSerializer < Plucker::Base
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }]
      expect(memory_store.keys.size).to eq(0)

      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooNoCacheSerializer)
      expect(serializer_instance.class.cache_enabled?).to eq(false)
      expect(serializer_instance.to_h).to eq(expected_result)
      expect(memory_store.keys.size).to eq(0)
    end

    it 'json collection by default' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooJsonCollectionSerializer < Plucker::Base
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }].to_json

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooJsonCollectionSerializer)
      expect(FooJsonCollectionSerializer.cache_enabled?).to eq(true)

      expect(serializer_instance.to_json).to eq(expected_result)
      expect(memory_store.keys.size).to eq(1) # Cache collection and nothing else
      key = memory_store.keys.last
      expect(key).to include('query')
      expect(key).to include('/json')
      expect(memory_store.read(key)).to eq(expected_result)
    end

    it 'json collection with plucking' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooJsonCollectionPluckingSerializer < Plucker::Base
        model Foo
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }].to_json

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooJsonCollectionPluckingSerializer)
      expect(FooJsonCollectionPluckingSerializer.cache_enabled?).to eq(true)

      expect(serializer_instance.to_json).to eq(expected_result)
      expect(memory_store.keys.size).to eq(1) # Cache collection and nothing else
      key = memory_store.keys.last
      expect(key).to include('query')
      expect(key).to include('/json')
      expect(memory_store.read(key)).to eq(expected_result)
    end

    it 'hash collection' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooHashCollectionSerializer < Plucker::Base
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }]

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooHashCollectionSerializer)
      expect(FooHashCollectionSerializer.cache_enabled?).to eq(true)

      expect(serializer_instance.to_h).to eq(expected_result)
      expect(memory_store.keys.size).to eq(1) # Cache collection and nothing else
      key = memory_store.keys.last
      expect(key).to include('query')
      expect(key).to include('/hash')
      expect(memory_store.read(key)).to eq(expected_result)
    end

    it 'hash collection with plucking' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooHashCollectionPluckSerializer < Plucker::Base
        model Foo
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ "name": foo.name, "address": foo.address },
                         { "name": foo1.name, "address": foo1.address }]

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooHashCollectionPluckSerializer)
      expect(FooHashCollectionPluckSerializer.cache_enabled?).to eq(true)

      expect(serializer_instance.to_h).to eq(expected_result)
      expect(memory_store.keys.size).to eq(1) # Cache collection and nothing else
      key = memory_store.keys.last
      expect(key).to include('query')
      expect(key).to include('/hash')
      expect(memory_store.read(key)).to eq(expected_result)
    end

    it 'json multi' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooJsonMultiSerializer < Plucker::Base
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }].to_json

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooJsonMultiSerializer, cache: :multi)
      expect(FooJsonMultiSerializer.cache_enabled?).to eq(true)
      expect(serializer_instance.to_json).to eq(expected_result)

      expect(memory_store.keys.size).to eq(2) # Cache single objects
      foo_serializer = FooJsonMultiSerializer.new(foo)
      foo1_serializer = FooJsonMultiSerializer.new(foo1)
      expect(memory_store.read(foo_serializer.cache_key)).to eq({ name: foo.name,
                                                                  address: foo.address }.to_json)
      expect(memory_store.read(foo1_serializer.cache_key)).to eq({ name: foo1.name,
                                                                   address: foo1.address }.to_json)
    end

    it 'json multi plucking' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooJsonMultiPluckingSerializer < Plucker::Base
        model Foo
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }].to_json

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooJsonMultiPluckingSerializer,
                                                             cache: :multi)
      expect(FooJsonMultiPluckingSerializer.cache_enabled?).to eq(true)
      expect(serializer_instance.to_json).to eq(expected_result)

      # Current behavior is that plucked collection will not cache single objects
      # Use collection cache in this case
      expect(memory_store.keys.size).to eq(0) # Cache single objects
    end

    it 'hash multi' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooHashMultiSerializer < Plucker::Base
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }]

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooHashMultiSerializer, cache: :multi)
      expect(FooHashMultiSerializer.cache_enabled?).to eq(true)
      expect(serializer_instance.to_h).to eq(expected_result)

      expect(memory_store.keys.size).to eq(2) # Cache single objects
      foo_serializer = FooHashMultiSerializer.new(foo)
      foo1_serializer = FooHashMultiSerializer.new(foo1)
      expect(memory_store.read(foo_serializer.cache_key(adapter: :hash))).to eq({ name: foo.name,
                                                                                  address: foo.address })
      expect(memory_store.read(foo1_serializer.cache_key(adapter: :hash))).to eq({ name: foo1.name,
                                                                                   address: foo1.address })
    end

    it 'hash multi plucking' do
      memory_store = InspectableMemoryStore.new
      Plucker.config.cache_store = memory_store

      class FooHashMultiPluckingSerializer < Plucker::Base
        model Foo
        cache
        attributes :name, :address
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      expected_result = [{ name: foo.name, address: foo.address },
                         { name: foo1.name, address: foo1.address }]

      expect(memory_store.keys.size).to eq(0)
      serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooHashMultiPluckingSerializer,
                                                             cache: :multi)
      expect(FooHashMultiPluckingSerializer.cache_enabled?).to eq(true)
      expect(serializer_instance.to_h).to eq(expected_result)

      # Current behavior is that plucked collection will not cache single objects
      # Use collection cache in this case
      expect(memory_store.keys.size).to eq(0)
    end
  end
end
