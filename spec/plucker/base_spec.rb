# frozen_string_literal: true
require "spec_helper"
require "active_record/connection_adapters/postgresql_adapter"

describe Plucker::Base do
  class FooSerializer < Plucker::Base
    attributes :name, :address
  end

  context "instantiation types" do
    it "from database" do
      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

      expect(FooSerializer.new(foo).to_h).to eq({name: foo.name, address: foo.address})
    end

    it "from memory" do
      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word)

      expect(FooSerializer.new(foo).to_h).to eq({name: foo.name, address: foo.address})
    end

    it "plain object" do
      class PlainFoo
        attr_accessor :name, :address

        def initialize(name, address)
          @name = name
          @address = address
        end
      end

      foo = PlainFoo.new(Faker::Lorem.word, Faker::Lorem.word)

      expect(FooSerializer.new(foo).to_h).to eq({name: foo.name, address: foo.address})
    end
  end

  context "attributes" do
    it "method attributes" do
      class FooWithMethodsSerializer < Plucker::Base
        attributes :name, :address, :something

        def something
            "#{object.name} #{object.address}"
        end

        def another_method
            raise "I shouldn't get called"
        end
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

      expect(FooWithMethodsSerializer.new(foo).to_h).to eq({name: foo.name, address: foo.address, something: "#{foo.name} #{foo.address}"})
    end

    it "method attributes with key" do
        class FooWithKeyAttributeSerializer < Plucker::Base
            attributes :name
            attribute :address, key: :addr
        end
  
        foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
  
        expect(FooWithKeyAttributeSerializer.new(foo).to_h).to eq({name: foo.name, addr: foo.address})
    end

    it "method attributes with block" do
        class FooWithBlockAttributeSerializer < Plucker::Base
            attributes :name
            attribute :address do |object|
                object.name
            end
        end
  
        foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
  
        expect(FooWithBlockAttributeSerializer.new(foo).to_h).to eq({name: foo.name, address: foo.name})
    end
  end
end