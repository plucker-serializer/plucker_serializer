# frozen_string_literal: true

module Plucker
  class Configuration
    attr_accessor :cache_store

    def initialize
      @cache_store = nil
    end
  end
end
