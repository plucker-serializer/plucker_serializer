require "plucker/version"
require "plucker/configuration"
require "plucker/base"
require "plucker/attribute"
require "plucker/collection"
require "plucker/relationship"
require "plucker/belongs_to"
require "plucker/has_one"
require "plucker/has_many"
require "plucker/field"
require "plucker/descriptor"
require "plucker/concerns/caching"

module Plucker
    class << self
        def config
            @config ||= Configuration.new
        end
  
        def configure
            yield(config)
        end
    end
end