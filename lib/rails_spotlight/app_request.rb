# frozen_string_literal: true

module RailsSpotlight
  class AppRequest
    attr_reader :id, :events

    def initialize(id)
      @id = id
      @events = []
    end

    def self.current
      Thread.current[:rails_spotlight_request_id]
    end

    def current!
      Thread.current[:rails_spotlight_request_id] = self
    end
  end
end
