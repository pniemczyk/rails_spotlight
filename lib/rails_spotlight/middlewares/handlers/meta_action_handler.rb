# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class MetaActionHandler < BaseActionHandler
        def execute; end

        private

        def json_response_body
          {
            events: events,
            project: ::RailsSpotlight.config.project_name
          }
        end

        def id
          @id ||= request.params['id']
        end

        def events
          @events ||= Storage.new(id).read || []
        end
      end
    end
  end
end
