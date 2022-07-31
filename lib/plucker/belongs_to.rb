# frozen_string_literal: true
require_relative "relationship"

module Plucker
    class BelongsTo < Plucker::Relationship
        def value(serializer)
            relationship_object = self.associated_object(serializer)
            return nil if relationship_object.blank?
            relationship_serializer(serializer, relationship_object).new(relationship_object).serializable_hash
        end
    end
end