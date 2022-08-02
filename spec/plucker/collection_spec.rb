# frozen_string_literal: true
require "spec_helper"
require "active_record/connection_adapters/postgresql_adapter"

describe Plucker::Collection do
    class FooSerializer < Plucker::Base
        attributes :name, :address
    end

    context "instantiation types" do
        it "from database" do
            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

            expect(Plucker::Collection.new(Foo.all, serializer: FooSerializer).to_h).to eq([{"name" => foo.name, "address" => foo.address}, {"name" => foo2.name, "address" => foo2.address}])
        end
    end

    context "custom options" do
        it "custom serializer" do
            class FooCustomSerializer < Plucker::Base
                attribute :name
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

            expect(Plucker::Collection.new(Foo.all, serializer: FooCustomSerializer).to_h).to eq([{"name" => foo.name}, {"name" => foo2.name}])
        end
    end

    context "plucking" do
        it "base" do
            class FooPluckedSerializer < Plucker::Base
                model Foo
                attribute :name
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

            expect(FooPluckedSerializer.is_pluckable?).to eq(true)
            expect(Plucker::Collection.new(Foo.all, serializer: FooPluckedSerializer).to_h).to eq([{"name" => foo.name}, {"name" => foo2.name}])
        end
    end
end