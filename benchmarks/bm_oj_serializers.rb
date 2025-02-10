# frozen_string_literal: true
require_relative "./benchmarking_support"
require_relative "./app"
require_relative "./setup"
require "active_record/connection_adapters/postgresql_adapter"

class AuthorFastSerializer < Oj::Serializer
  attributes :id, :name
end

class TagSerializer < Oj::Serializer
  attributes :display_name, :description
end

class PostFastSerializer < Oj::Serializer
  attributes :id, :body, :title, :author_id
end

class PostWithHasOneFastSerializer < Oj::Serializer
  attributes :id, :body, :title, :author_id

  has_one :author, serializer: AuthorFastSerializer
end

class PostHasManySerializer < Oj::Serializer
  attributes :id, :body, :title, :author_id

  has_many :tags, serializer: TagSerializer
end

def benchmark(prefix, serializer, options = {})
  Benchmark.run("Oj_ActiveRecord_#{prefix}_Posts_50") do
    posts_50 = Post.all.limit(50)
    serializer.render(posts_50).to_json
  end

  Benchmark.run("Oj_ActiveRecord_#{prefix}_Posts_1000") do
    posts = Post.all.limit(1000).includes(:author)
    serializer.render(posts).to_json
  end
end

benchmark "Simple", PostFastSerializer
benchmark "HasOne", PostWithHasOneFastSerializer
benchmark "HasMany", PostHasManySerializer