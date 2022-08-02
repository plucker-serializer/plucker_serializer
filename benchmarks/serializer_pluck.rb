# frozen_string_literal: true
require_relative "./app"
require_relative "./setup"
require 'benchmark'

class PostNoPluckingSerializer < Plucker::Base
    attributes :id, :body, :title, :updated_at
end

class PostSerializer < Plucker::Base
    model Post
    attributes :id, :body, :title, :updated_at
end

n = 10
Benchmark.bm do |x|
    x.report {
        n.times do
            posts = Post.all
            Plucker::Collection.new(posts, serializer: PostNoPluckingSerializer).to_json
        end
    }
    x.report {
        n.times do
            posts = Post.all
            Plucker::Collection.new(posts, serializer: PostSerializer).to_json
        end
    }
end