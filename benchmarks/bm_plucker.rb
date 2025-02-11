# frozen_string_literal: true

require_relative './benchmarking_support'
require_relative './app'
require_relative './setup'

class PluckerAuthorFastSerializer < Plucker::Base
  model Author
  attributes :id, :name
end

class PluckerTagSerializer < Plucker::Base
  model Tag
  attributes :display_name, :description
end

class PluckerPostNoPluckingSerializer < Plucker::Base
  attributes :id, :body, :title, :author_id
end

class PluckerPostFastSerializer < Plucker::Base
  model Post
  attributes :id, :body, :title, :author_id
end

class PluckerPostHasOneSerializer < Plucker::Base
  model Post
  attributes :id, :body, :title, :author_id

  has_one :author, serializer: PluckerAuthorFastSerializer
end

class PluckerPostHasManySerializer < Plucker::Base
  model Post
  attributes :id, :body, :title, :author_id

  has_many :tags, serializer: PluckerTagSerializer
end

def benchmark_plucker(prefix, serializer, options = {})
  merged_options = options.merge(each_serializer: serializer)

  Benchmark.run("Plucker_#{prefix}_Posts_50") do
    posts_50 = Post.all.limit(50)
    Plucker::Collection.new(posts_50, serializer: serializer).to_json
  end

  Benchmark.run("Plucker_#{prefix}_Posts_1000") do
    posts = Post.all.limit(1000).includes(:author)
    Plucker::Collection.new(posts, serializer: serializer).to_json
  end
end

def benchmark_plucker_memory(prefix, serializer, options = {})
  GC.start
  mem_before = GetProcessMem.new.mb

  report = MemoryProfiler.report(allow_files: 'plucker_serializer') do
    Post.all.limit(100).each do |post|
      json = serializer.new(post).as_json
    end
  end

  GC.start
  mem_after = GetProcessMem.new.mb

  report.pretty_print(scale_bytes: true)

  leaked = mem_after - mem_before
  puts "Memory before: #{mem_before} MB"
  puts "Memory after: #{mem_after} MB"
  puts "Memory diff (leaked): #{leaked} MB"
end

benchmark_plucker 'Simple', PluckerPostFastSerializer
benchmark_plucker 'HasOne', PluckerPostHasOneSerializer
benchmark_plucker 'HasMany', PluckerPostHasManySerializer
# benchmark_plucker_memory 'Simple', PluckerPostHasManySerializer
