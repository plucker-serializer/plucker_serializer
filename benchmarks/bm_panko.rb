# frozen_string_literal: true
require_relative "./benchmarking_support"
require_relative "./app"
require_relative "./setup"
require "active_record/connection_adapters/postgresql_adapter"

class AuthorFastSerializer < Panko::Serializer
  attributes :id, :name
end

class TagSerializer < Panko::Serializer
  attributes :display_name, :description, :created_at
end

class PostFastSerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id, :created_at
end

class PostWithHasOneFastSerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id, :created_at

  has_one :author, serializer: AuthorFastSerializer
end

class PostHasManySerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id, :created_at

  has_many :tags, serializer: TagSerializer
end

def benchmark(prefix, serializer, options = {})
  merged_options = options.merge(each_serializer: serializer)

  Benchmark.run("Panko_ActiveRecord_#{prefix}_Posts_50") do
    posts_50 = Post.all.limit(50)
    Panko::ArraySerializer.new(posts_50, merged_options).to_json
  end

  Benchmark.run("Panko_ActiveRecord_#{prefix}_Posts_1000") do
    posts = Post.all.limit(1000).includes(:author)
    Panko::ArraySerializer.new(posts, merged_options).to_json
  end
end

benchmark "Simple", PostFastSerializer
benchmark "HasOne", PostWithHasOneFastSerializer
benchmark "HasMany", PostHasManySerializer