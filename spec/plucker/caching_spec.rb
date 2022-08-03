# frozen_string_literal: true
require "spec_helper"
require "active_record/connection_adapters/postgresql_adapter"

describe Plucker::Caching do
    context "cache configuration" do
        it "caches default" do
            class FooCacheSerializer < Plucker::Base
                cache
                attributes :name, :address
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            
            serializer_instance = FooCacheSerializer.new(foo)
            expect(FooCacheSerializer.cache_enabled?).to eq(true)
            expect(serializer_instance.to_h).to eq({"name" => foo.name, "address" => foo.address})
        end

        it "no caching if option not passed" do
            memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
            Plucker.config.cache_store = memory_store

            class FooNoCacheSerializer < Plucker::Base
                attributes :name, :address
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            cache_key = foo.cache_key + "/" +  Digest::SHA1.hexdigest("FooNoCacheSerializer")
            expect(memory_store.exist?(cache_key)).to be(false)
            
            serializer_instance = FooNoCacheSerializer.new(foo)
            expect(FooNoCacheSerializer.cache_enabled?).to eq(false)
            expect(serializer_instance.to_h).to eq({"name" => foo.name, "address" => foo.address})

            expect(serializer_instance.cache_key).to eq(cache_key)
            expect(memory_store.exist?(cache_key)).to be(false)
        end

        it "custom cache store" do
            memory_store = ActiveSupport::Cache.lookup_store(:memory_store)
            Plucker.config.cache_store = memory_store

            class FooMemoryCacheSerializer < Plucker::Base
                cache
                attributes :name, :address
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            cache_key = foo.cache_key + "/" +  Digest::SHA1.hexdigest("FooMemoryCacheSerializer")
            expect(memory_store.exist?(cache_key)).to be(false)
            
            serializer_instance = FooMemoryCacheSerializer.new(foo)
            expect(FooMemoryCacheSerializer.cache_enabled?).to eq(true)
            expect(serializer_instance.to_h).to eq({"name" => foo.name, "address" => foo.address})

            expect(serializer_instance.cache_key).to eq(cache_key)
            expect(memory_store.exist?(cache_key)).to be(true)
        end
    end

    context "collection caching" do
        class InspectableMemoryStore < ActiveSupport::Cache::MemoryStore
            def keys
              @data.keys
            end
        end
        
        it "use collection cache by default" do
            memory_store = InspectableMemoryStore.new
            Plucker.config.cache_store = memory_store

            class FooCacheSerializer < Plucker::Base
                cache
                attributes :name, :address
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
        
            expect(memory_store.keys.size).to eq(0)
            serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooCacheSerializer)
            expect(FooCacheSerializer.cache_enabled?).to eq(true)
            expect(serializer_instance.to_h).to eq([{"name" => foo.name, "address" => foo.address}, {"name" => foo1.name, "address" => foo1.address}])
            expect(memory_store.keys.size).to eq(3) # Cache collection & two objects
        end

        it "use multi cache" do
            memory_store = InspectableMemoryStore.new
            Plucker.config.cache_store = memory_store

            class FooCacheSerializer < Plucker::Base
                cache
                attributes :name, :address
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
        
            expect(memory_store.keys.size).to eq(0)
            serializer_instance = Plucker::Collection.new(Foo.all, serializer: FooCacheSerializer, cache: :multi)
            expect(FooCacheSerializer.cache_enabled?).to eq(true)
            expect(serializer_instance.to_h).to eq([{"name" => foo.name, "address" => foo.address}, {"name" => foo1.name, "address" => foo1.address}])
            expect(memory_store.keys.size).to eq(2) # Cache two objects
        end
    end
end