# frozen_string_literal: true
require_relative "./benchmarking_support"
require_relative "./app"
require_relative "./setup"

# disable logging for benchmarks
ActiveModelSerializers.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new('/dev/null'))

class AmsAuthorFastSerializer < ActiveModel::Serializer
  attributes :id, :name
end

class AmsPostFastSerializer < ActiveModel::Serializer
  attributes :id, :body, :title, :author_id, :created_at
end

class AmsPostWithHasOneFastSerializer < ActiveModel::Serializer
  attributes :id, :body, :title, :author_id

  has_one :author, serializer: AmsAuthorFastSerializer
end

class AmsAuthorWithHasManyFastSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :posts, serializer: AmsPostFastSerializer
end

def benchmark_ams(prefix, serializer, options = {})
  merged_options = options.merge(each_serializer: serializer)

  data = Benchmark.data
  posts = Post.all.includes(:author)

  Benchmark.run("AMS_#{prefix}_Posts_#{posts.count}") do
    ActiveModelSerializers::SerializableResource.new(posts, merged_options).to_json
  end

  posts_50 = Post.all.limit(50)

  Benchmark.run("AMS_#{prefix}_Posts_50") do
    ActiveModelSerializers::SerializableResource.new(posts_50, merged_options).to_json
  end
end

benchmark_ams "Attributes_Simple", AmsPostFastSerializer
benchmark_ams "Attributes_HasOne", AmsPostWithHasOneFastSerializer
#benchmark_ams "Attributes_HasMany", AmsAuthorWithHasManyFastSerializer