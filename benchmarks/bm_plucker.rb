# frozen_string_literal: true
require_relative "./benchmarking_support"
require_relative "./app"
require_relative "./setup"

class PluckerAuthorFastSerializer < Plucker::Base
    attributes :id, :name
end

class PluckerPostFastSerializer < Plucker::Base
    attributes :id, :body, :title, :created_at
    attribute :authori do |object|
        object.author_id
    end
end

class PluckerPostWithHasOneFastSerializer < Plucker::Base
    attributes :id, :body, :title, :author_id

    has_one :author, serializer: PluckerAuthorFastSerializer
end

class PluckerAuthorWithHasManyFastSerializer < Plucker::Base
    attributes :id, :name

    has_many :posts, serializer: PluckerPostFastSerializer
end

def benchmark_plucker(prefix, serializer, options = {})
    merged_options = options.merge(each_serializer: serializer)

    data = Benchmark.data
    posts = Post.all.includes(:author)

    Benchmark.run("Plucker_#{prefix}_Posts_#{posts.count}") do
        Plucker::Collection.new(posts, serializer: serializer).to_h
    end

    posts_50 = Post.all.limit(50)

    Benchmark.run("Plucker_#{prefix}_Posts_50") do
        Plucker::Collection.new(posts_50, serializer: serializer).to_h
    end
end
  
benchmark_plucker "Simple", PluckerPostFastSerializer
benchmark_plucker "HasOne", PluckerPostWithHasOneFastSerializer
#benchmark_plucker "HasMany", PluckerAuthorWithHasManyFastSerializer