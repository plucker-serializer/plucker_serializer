# Plucker Serializer

[![Gem Version](https://badge.fury.io/rb/plucker_serializer.svg)](https://badge.fury.io/rb/plucker_serializer)

## About

Plucker serializer is a fast JSON serializer for ActiveRecord and Ruby objects. It is inspired by ActiveModelSerializers and Panko, and brings performance enhancements for real world Rails APIs. 

The interface is very close to ActiveModelSerializers and Panko.

Plucker was created with performance in mind, and is most suitable for Rails APIs.

It uses different methods to achieve high throughput and low memory consumption :

- Plucker uses ActiveRecord's `pluck` function when possible to avoid going through ActiveRecord instantiation and to optimize
  database queries. 
- Serializer metadata is computed ahead of time, when serializer classes are parsed. Serializers have a `_descriptor` class attribute
  which contains all the information necessary to compute the serialization.
- Plucker offers built-in caching for single objects, collections and associations. Caching associations and collections can result in great performance enhancements compared to simple single object caching.


## Installation

To install Plucker, add this line to your application's Gemfile:

```
gem 'plucker_serializer'
```

And then execute:

```
$ bundle install
```

## Getting Started

To create a serializer, create a class that inherits from `Plucker::Base` :

``` ruby
class PostSerializer < Plucker::Base
  attributes :title
end

class UserSerializer < Plucker::Base
  attributes :id, :name, :age

  has_many :posts, serializer: PostSerializer
end
```

To get the hash or JSON output for an object, instantiate your serializer class with an object and call `to_hash`, `to_h`, or `to_json` :
``` ruby
post = Post.last
post_serialized = PostSerializer.new(post).to_json
```
``` json
{ "title": "my-post-title" }
```


and for a collection of objects, use the `Plucker::Collection` class :
``` ruby
posts = Post.all
posts_serialized = Plucker::Collection.new(posts).to_json
```
``` json
[{ "title": "my-post-title" }, { "title": "my-second-post-title" }]
```

## Describing your objects with Plucker

### Attributes

A serializer can define attributes with the `attribute` and `attributes` functions.
``` ruby
class PostSerializer < Plucker::Base
  attributes :title, :created_at
  attribute :description
end
```

Attributes must be attributes of the serialized object, or they can come from a serializer method or block.
``` ruby
class PostSerializer < Plucker::Base
  attribute :method_attribute
  attribute :block_attribute do |object|
    object.title.capitalize
  end

  def method_attribute
    # object represents the serialized object and is available in the method context
    object.title.parameterize
  end
end
```

A key option can be passed to an attribute to define a different key in the serialized output :
``` ruby
class PostSerializer < Plucker::Base
  attributes :title
  attribute :description, key: :summary
end
```
``` json
{ "title": "my-post-title", "summary": "my-post-description" }
```

### Associations

A serializer can define `belongs_to`, `has_one` and `has_many` associations to fetch associated objects.
``` ruby
class PostSerializer < Plucker::Base
    attributes :title, :description

    has_one :author # AuthorSerializer will be used
    belongs_to :category, key: :section # CategorySerializer will be used
    has_many :tags, serializer: TagCustomSerializer
end

class AuthorSerializer < Plucker::Base
    attributes :first_name, :last_name
end

class CategorySerializer < Plucker::Base
    attributes :id, :display_name
end

class TagCustomSerializer < Plucker::Base
    attributes :id, :display_name
end
```

By default, Plucker will use the `${MODEL}Serializer` serializer class for associations, but you can pass a custom serializer
with the `serializer` option. Plucker will use the name of the model and not the name of the association, so for example if you
have an `author` association that links a Post to a User, Plucker will use the `UserSerializer` class by default.

As for attributes, it is also possible to pass a custom key for an association, and to add a block :

``` ruby
class PostSerializer < Plucker::Base
    attributes :title, :description
    
    has_many :tags, serializer: TagCustomSerializer do |object|
      # block must return an ActiveRecord::Collection
      object.tags.limit(1)
    end
end
```

### Model and serializer classes

Plucker must know the model name that is represented by the serializer. 
By default, it will use the beginning of your serializer class name.
If your class is called `PostSerializer`, the model used will be `Post`. If your class is called `PostTagSerializer`, the model used will be `PostTag`.

If you class name is different from the model name, use the `model` option to tell Plucker which model to use :
``` ruby
class PostCustomSerializer < Plucker::Base
    model Post
    attributes :title
end
```

For collections, as for associations, Plucker will use the serialized object class to compute the serializer class, but you can pass a custom serializer :
``` ruby
posts = Post.all
# Plucker will use the PostSerializer class by default
posts_serialized = Plucker::Collection.new(posts).to_json

# Use the serializer option to pass a custom serializer
posts_serialized_custom = Plucker::Collection.new(posts, serializer: CustomPostSerializer).to_json
```

## Caching

Plucker has built-in caching for single objects, collections and associations.
To enable caching, create an initializer `plucker.rb` and define a cache store :
``` ruby
Plucker.configure do |config|
  config.cache_store = Rails.cache
end
```

Then enable caching in each serializer with the `cache` option:
``` ruby
class PostCustomSerializer < Plucker::Base
    cache
    attributes :title
end
```

Plucker uses ActiveRecord's `cache_key` and `cache_version` for single objects and collections.

When caching a collection, ActiveRecord will query the database to get the last updated object. The cache key
will include a hash of the SQL query.
This can be a performance issue in some cases, depending on your application.
To avoid collection caching, use the `cache` option with `multi` when instantiating the collection :
``` ruby
posts = Post.all
posts_serialized = Plucker::Collection.new(posts, cache: :multi)
```
This will tell Plucker to not cache the whole collection but to cache each object separately.


## Tests

Tests are written with [RSpec](https://rspec.info/).
To run tests, run command :
```
$ rspec
```


## Benchmarks

Benchmarks are available in the `benchmarks` folder, to compare Plucker with ActiveModelSerializers and Panko.
To run benchmarks, use the rake command :
```
$ rake benchmarks
```

### Plucker

| Benchmark                   | ip/s     | allocs/retained |
|-----------------------------|----------|-----------------|
| Plucker_Simple_Posts_50     | 1,855.78 | 867/5           |
| Plucker_Simple_Posts_1000   | 121.4    | 16199/126       |
| Plucker_HasOne_Posts_50     | 87.53    | 10424/83        |
| Plucker_HasOne_Posts_1000   | 21.83    | 78779/75        |
| Plucker_HasMany_Posts_50    | 45.47    | 25023/72        |
| Plucker_HasMany_Posts_1000  | 2.27     | 497243/2        |


### Panko

| Benchmark                              | ip/s     | allocs/retained |
|----------------------------------------|----------|-----------------|
| Panko_ActiveRecord_Simple_Posts_50     | 2,306.29 | 721/24          |
| Panko_ActiveRecord_Simple_Posts_1000   | 39.01    | 30799/81        |
| Panko_ActiveRecord_HasOne_Posts_50     | 92.5     | 8187/80         |
| Panko_ActiveRecord_HasOne_Posts_1000   | 39.19    | 31262/22026     |
| Panko_ActiveRecord_HasMany_Posts_50    | 55.52    | 16893/102       |
| Panko_ActiveRecord_HasMany_Posts_1000  | 2.63     | 331262/168026   |


### ActiveModelSerializers 0.10

| Benchmark               | ip/s   | allocs/retained |
|-------------------------|--------|-----------------|
| AMS_Simple_Posts_50     | 291.05 | 4625/162        |
| AMS_Simple_Posts_1000   | 11.84  | 88838/77        |
| AMS_HasOne_Posts_50     | 56.93  | 14456/87        |
| AMS_HasOne_Posts_1000   | 6.02   | 155293/2        |
| AMS_HasMany_Posts_50    | 20.26  | 45199/109       |
| AMS_HasMany_Posts_1000  | 1.03   | 895293/2        |


Plucker shows significant performance improvements compared to ActiveModelSerializer.

When comparing to Panko, we can also see improvements in throughput and memory in some cases, thanks to the plucking strategy. Plucker is especially good in the case of objects with only attributes.

Panko seems to have memory problems for large collections.

The benchmarks do not use caching, and Plucker would see a huge boost compared to Panko if caching were enabled. We did not add it to the benchmarks because the comparison would not make sense as Panko does not enable caching.


## License

The gem is available as open source under the terms of the MIT License.
