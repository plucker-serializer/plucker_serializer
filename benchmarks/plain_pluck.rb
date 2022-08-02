# frozen_string_literal: true
require_relative "./setup"
require 'benchmark'
require "pluck_all"

#
# This benchmark compares the performance of object retrieval with pluck and select
# It also shows the impact of timestamp type casting
#

n = 10
Benchmark.bm do |x|
    x.report {
        n.times do
            posts = Post.all.pluck(:id, :title, :updated_at)
            attrs = [:id, :title, :updated_at]
            posts.as_json.map { |el| attrs.zip(el).to_h }.to_json
        end
    }
    x.report {
        n.times do
            posts_json = Post.all.pluck_all(:id, :title, :updated_at).to_json
        end
    }
    x.report {
        n.times do
            posts_json = Post.all.pluck_all(:id, :title, 'updated_at AS updated_at_before_type_cast').to_json
        end
    }
    x.report {
        n.times do
            posts = Post.select(:id, :title, :updated_at).all
            posts.to_json
        end
    }
    x.report {
        n.times do
            posts = Post.all
            posts.to_json
        end
    }
end