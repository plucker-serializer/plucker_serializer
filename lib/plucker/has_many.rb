# frozen_string_literal: true
require_relative "relationship"
require_relative "collection"

module Plucker
    class HasMany < Plucker::Relationship
        def value(serializer)
            Plucker::Collection.new(self.associated_object(serializer), serializer: relationship_serializer(serializer)).serializable_hash
        end
    end
end