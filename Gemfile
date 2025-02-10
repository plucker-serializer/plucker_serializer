# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

raw_rails_version = ENV.fetch('RAILS_VERSION', '7.2.2')
rails_version = "~> #{raw_rails_version}"

gem 'activemodel', rails_version
gem 'activerecord', rails_version, group: :test
gem 'activesupport', rails_version
gem 'oj', '~> 3.16.9'
gem 'pluck_all', '~> 2.3.4'

group :benchmarks do
  gem 'pg', '>= 0.18', '< 2.0'
  gem 'sqlite3', '~> 1.4'

  gem 'memory_profiler'
  gem 'ruby-prof', platforms: [:mri]
  gem 'ruby-prof-flamegraph', platforms: [:mri]

  gem 'active_model_serializers'
  gem 'benchmark-ips'
  gem 'panko_serializer'
  gem 'terminal-table'
end

group :test do
  gem 'faker'
end

group :development do
  gem 'byebug'
  gem 'rake'
  gem 'rake-compiler'
  gem 'rspec', '~> 3.0'
  gem 'rubocop'
end
