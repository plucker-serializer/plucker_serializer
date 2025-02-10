# frozen_string_literal: true

require 'spec_helper'
require 'active_record/connection_adapters/postgresql_adapter'

describe Plucker::Base do
  class FooSerializer < Plucker::Base
    attributes :name, :address
  end

  context 'instantiation types' do
    it 'from database' do
      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

      expect(FooSerializer.new(foo).to_h).to eq({ name: foo.name, address: foo.address })
      expect(FooSerializer.new(foo).to_json).to eq({ name: foo.name, address: foo.address }.to_json)
    end

    it 'from memory' do
      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word)

      expect(FooSerializer.new(foo).to_h).to eq({ name: foo.name, address: foo.address })
      expect(FooSerializer.new(foo).to_json).to eq({ name: foo.name, address: foo.address }.to_json)
    end

    it 'as_json' do
      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word)

      expect(FooSerializer.new(foo).as_json).to eq({ name: foo.name, address: foo.address })
      expect(FooSerializer.new(foo).to_json).to eq({ name: foo.name, address: foo.address }.to_json)
    end

    it 'plain object' do
      class PlainFoo
        attr_accessor :name, :address

        def initialize(name, address)
          @name = name
          @address = address
        end
      end

      foo = PlainFoo.new(Faker::Lorem.word, Faker::Lorem.word)

      expect(FooSerializer.new(foo).to_h).to eq({ name: foo.name, address: foo.address })
    end
  end

  context 'attributes' do
    it 'method attributes' do
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

      expect(FooWithMethodsSerializer.new(foo).to_h).to eq({ name: foo.name, address: foo.address,
                                                             something: "#{foo.name} #{foo.address}" })
      expect(FooWithMethodsSerializer.new(foo).to_json).to eq({ name: foo.name, address: foo.address,
                                                                something: "#{foo.name} #{foo.address}" }.to_json)
    end

    it 'method attributes with key' do
      class FooWithKeyAttributeSerializer < Plucker::Base
        attributes :name
        attribute :address, key: :addr
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

      expect(FooWithKeyAttributeSerializer.new(foo).to_h).to eq({ name: foo.name, addr: foo.address })
    end

    it 'method attributes with block' do
      class FooWithBlockAttributeSerializer < Plucker::Base
        attributes :name
        attribute :address do |object|
          object.name
        end
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

      expect(FooWithBlockAttributeSerializer.new(foo).to_h).to eq({ name: foo.name, address: foo.name })
      expect(FooWithBlockAttributeSerializer.new(foo).to_json).to eq({ name: foo.name, address: foo.name }.to_json)
    end

    it 'attribute with false condition' do
      class FooFalseConditionAttributeSerializer < Plucker::Base
        attributes :name
        attribute :address, if: :should_include_address?

        def should_include_address?
          false
        end
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

      expect(FooFalseConditionAttributeSerializer.new(foo).to_h).to eq({ name: foo.name })
    end

    it 'attribute with true condition' do
      class FooTrueConditionAttributeSerializer < Plucker::Base
        attributes :name
        attribute :address, if: :should_include_address?

        def should_include_address?
          true
        end
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload

      expect(FooTrueConditionAttributeSerializer.new(foo).to_h).to eq({ name: foo.name, address: foo.address })
    end
  end

  context 'associations' do
    it 'has_one' do
      class FooHolderSerializer < Plucker::Base
        attributes :name

        has_one :foo
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo_holder = FooHolder.create(name: Faker::Lorem.word, foo: foo).reload

      expect(FooHolderSerializer.new(foo_holder).to_h).to eq({ name: foo_holder.name,
                                                               foo: { name: foo.name,
                                                                      address: foo.address } })
      expect(FooHolderSerializer.new(foo_holder).to_json).to eq({ name: foo_holder.name,
                                                                  foo: { name: foo.name,
                                                                         address: foo.address } }.to_json)
    end

    it 'has_one with key' do
      class FooHolderWithKeySerializer < Plucker::Base
        attributes :name

        has_one :foo, key: :bar
      end

      foo = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo_holder = FooHolder.create(name: Faker::Lorem.word, foo: foo).reload

      expect(FooHolderWithKeySerializer.new(foo_holder).to_h).to eq({ name: foo_holder.name,
                                                                      bar: { name: foo.name,
                                                                             address: foo.address } })
    end

    it 'has_many' do
      class FoosHolderSerializer < Plucker::Base
        attributes :name

        has_many :foos
      end

      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foos_holder = FoosHolder.create(name: Faker::Lorem.word)
      foos_holder.foos << foo1
      foos_holder.foos << foo2
      foos_holder.reload

      expect(foos_holder.foos.size).to eq(2)
      expect(FoosHolderSerializer.new(foos_holder).to_h).to eq({ name: foos_holder.name,
                                                                 foos: [
                                                                   { name: foo1.name,
                                                                     address: foo1.address }, { name: foo2.name, address: foo2.address }
                                                                 ] })

      expect(FoosHolderSerializer.new(foos_holder).to_json).to eq({ name: foos_holder.name,
                                                                    foos: [
                                                                      { name: foo1.name,
                                                                        address: foo1.address }, { name: foo2.name, address: foo2.address }
                                                                    ] }.to_json)
    end

    it 'has_many custom serializer' do
      class FooCustomSerializer < Plucker::Base
        attributes :name
      end

      class FoosHolderCustomSerializer < Plucker::Base
        attributes :name

        has_many :foos, serializer: FooCustomSerializer
      end

      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foos_holder = FoosHolder.create(name: Faker::Lorem.word)
      foos_holder.foos << foo1
      foos_holder.foos << foo2
      foos_holder.reload

      expect(foos_holder.foos.size).to eq(2)
      expect(FoosHolderCustomSerializer.new(foos_holder).to_h).to eq({ name: foos_holder.name,
                                                                       foos: [{ name: foo1.name },
                                                                              { name: foo2.name }] })
    end

    it 'has_many with block' do
      class FooCustomBlockSerializer < Plucker::Base
        attributes :name
      end

      class FoosHolderCustomBlockSerializer < Plucker::Base
        attributes :name

        has_many :foos, serializer: FooCustomBlockSerializer do |object|
          object.foos.limit(1)
        end
      end

      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foos_holder = FoosHolder.create(name: Faker::Lorem.word)
      foos_holder.foos << foo1
      foos_holder.foos << foo2
      foos_holder.reload

      expect(foos_holder.foos.size).to eq(2)
      expect(FoosHolderCustomBlockSerializer.new(foos_holder).to_h).to eq({ name: foos_holder.name,
                                                                            foos: [{ name: foo1.name }] })
    end
  end
end
