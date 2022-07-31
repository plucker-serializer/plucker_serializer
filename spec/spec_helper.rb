
# frozen_string_literal: true

require "bundler/setup"
require "plucker_serializer"
require "faker"
require "active_support/all"

require_relative "models"

RSpec.configure do |config|
  config.order = :random

  config.before(:each) do
    FooHolder.delete_all
    FoosHolder.delete_all
    Foo.delete_all
  end
end