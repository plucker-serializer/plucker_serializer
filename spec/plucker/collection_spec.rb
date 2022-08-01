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

            expect(Plucker::Collection.new(Foo.all, serializer: FooSerializer).to_h).to eq([{name: foo.name, address: foo.address, updated_at: foo.updated_at}, 
                                                                                               {name: foo2.name, address: foo2.address, updated_at: foo2.updated_at}])
        end
    end

    context "custom options" do
        it "custom serializer" do
            class FooCustomSerializer < Plucker::Base
                attributes :name
            end

            foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
            foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

            expect(Plucker::Collection.new(Foo.all, serializer: FooCustomSerializer).to_h).to eq([{name: foo.name}, {name: foo2.name}])
        end
    end
end