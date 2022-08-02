# frozen_string_literal: true
require_relative "./benchmarking_support"
require_relative "./app"
require_relative "./setup"

class PluckerAuthorFastSerializer < Plucker::Base
    model Author
    attributes :id, :name
end

class PluckerPostNoPluckingSerializer < Plucker::Base
    attributes :id, :body, :title, :author_id, :created_at
end

class PluckerPostFastSerializer < Plucker::Base
    model Post
    attributes :id, :body, :title, :author_id, :created_at
end

class PluckerPostWithHasOneFastSerializer < Plucker::Base
    model Post
    attributes :id, :body, :title, :author_id, :created_at

    has_one :author, serializer: PluckerAuthorFastSerializer
end

class PluckerAuthorWithHasManyFastSerializer < Plucker::Base
    model Author
    attributes :id, :name

    has_many :posts, serializer: PluckerPostFastSerializer
end

def benchmark_plucker(prefix, serializer, options = {})
    merged_options = options.merge(each_serializer: serializer)

    Benchmark.run("Plucker_#{prefix}_Posts_50") do
        posts_50 = Post.all.limit(50)
        Plucker::Collection.new(posts_50, serializer: serializer).to_json
    end

    Benchmark.run("Plucker_#{prefix}_Posts_10000") do
        posts = Post.all.includes(:author)
        Plucker::Collection.new(posts, serializer: serializer).to_json
    end
end

benchmark_plucker "No Plucking", PluckerPostNoPluckingSerializer
benchmark_plucker "Simple", PluckerPostFastSerializer
benchmark_plucker "HasOne", PluckerPostWithHasOneFastSerializer
#benchmark_plucker "HasMany", PluckerAuthorWithHasManyFastSerializer