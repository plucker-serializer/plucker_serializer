# frozen_string_literal: true
require_relative "./benchmarking_support"
require_relative "./app"
require_relative "./setup"

# disable logging for benchmarks
ActiveModelSerializers.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new('/dev/null'))

class AmsAuthorFastSerializer < ActiveModel::Serializer
  attributes :id, :name
end

class AmsTagSerializer < ActiveModel::Serializer
  attributes :display_name, :description, :created_at
end

class AmsPostFastSerializer < ActiveModel::Serializer
  attributes :id, :body, :title, :author_id, :created_at
end

class AmsPostWithHasOneFastSerializer < ActiveModel::Serializer
  attributes :id, :body, :title, :author_id, :created_at

  has_one :author, serializer: AmsAuthorFastSerializer
end

class AmsPostHasManySerializer < ActiveModel::Serializer
  attributes :id, :body, :title, :author_id, :created_at

  has_many :tags, serializer: AmsTagSerializer
end

def benchmark_ams(prefix, serializer, options = {})
  merged_options = options.merge(each_serializer: serializer)

  Benchmark.run("AMS_#{prefix}_Posts_50") do
    posts_50 = Post.all.limit(50)
    ActiveModelSerializers::SerializableResource.new(posts_50, merged_options).to_json
  end

  Benchmark.run("AMS_#{prefix}_Posts_1000") do
    posts = Post.all.limit(1000).includes(:author)
    ActiveModelSerializers::SerializableResource.new(posts, merged_options).to_json
  end
end

benchmark_ams "Simple", AmsPostFastSerializer
benchmark_ams "HasOne", AmsPostWithHasOneFastSerializer
benchmark_ams "HasMany", AmsPostHasManySerializer