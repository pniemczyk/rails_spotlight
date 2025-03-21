# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class MetaActionHandler < BaseActionHandler
        def execute; end

        private

        def json_response_body
          {
            events:,
            root_path: ::RailsSpotlight.config.rails_root
          }
        end

        def id = @id ||= request.params['id']
        def events = @events ||= Storage.new(id).read || []
      end
    end
  end
end
