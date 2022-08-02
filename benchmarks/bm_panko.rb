# frozen_string_literal: true
require_relative "./benchmarking_support"
require_relative "./app"
require_relative "./setup"
require "active_record/connection_adapters/postgresql_adapter"

class AuthorFastSerializer < Panko::Serializer
  attributes :id, :name
end

class PostFastSerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id, :created_at
end

class PostWithHasOneFastSerializer < Panko::Serializer
  attributes :id, :body, :title, :author_id, :created_at

  has_one :author, serializer: AuthorFastSerializer
end

class AuthorWithHasManyFastSerializer < Panko::Serializer
  attributes :id, :name

  has_many :posts, serializer: PostFastSerializer
end


def benchmark(prefix, serializer, options = {})
  merged_options = options.merge(each_serializer: serializer)

  Benchmark.run("Panko_ActiveRecord_#{prefix}_Posts_50") do
    posts_50 = Post.all.limit(50)
    Panko::ArraySerializer.new(posts_50, merged_options).to_json
  end

  Benchmark.run("Panko_ActiveRecord_#{prefix}_Posts_10000") do
    posts = Post.all.includes(:author)
    Panko::ArraySerializer.new(posts, merged_options).to_json
  end
end

benchmark "Simple", PostFastSerializer
benchmark "HasOne", PostWithHasOneFastSerializer
#benchmark "HasMany", AuthorWithHasManyFastSerializer