# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plucker/version'

Gem::Specification.new do |s|
    s.name        = "plucker_serializer"
    s.version     = Plucker::VERSION
    s.summary = "A blazing fast JSON serializer for ActiveRecord & Ruby objects"
    s.description = "A blazing fast JSON serializer for ActiveRecord & Ruby objects"
    s.authors     = ["Henry Boisgibault"]
    s.email       = "henry@logora.fr"
    s.files = Dir['lib/**/*']
    s.require_paths = ["lib"]
    s.license       = "MIT"
    s.required_ruby_version = ">= 2.5.0"
    s.homepage      = "https://github.com/plucker-serializer/plucker_serializer"
    s.metadata = {
        "bug_tracker_uri" => "https://github.com/plucker-serializer/plucker_serializer/issues",
        "source_code_uri" => "https://github.com/plucker-serializer/plucker_serializer",
        "documentation_uri" => "https://github.com/plucker-serializer/plucker_serializer",
        "changelog_uri" => "https://github.com/plucker-serializer/plucker_serializer/releases"
    }

    s.add_dependency "activesupport"
    s.add_dependency "oj"
    s.add_dependency "pluck_all"
end