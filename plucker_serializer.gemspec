# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plucker/version'

Gem::Specification.new do |s|
    s.name        = "plucker_serializer"
    s.version     = Plucker::VERSION
    s.summary     = "A blazing fast JSON serializer with an easy-to-use API"
    s.description = "A blazing fast JSON serializer"
    s.authors     = ["Henry Boisgibault"]
    s.email       = "henry@logora.fr"
    s.files = Dir['lib/**/*']
    s.require_paths = ["lib"]
    s.license       = "MIT"
    s.required_ruby_version = ">= 2.5.0"

    s.add_dependency "activesupport"
end