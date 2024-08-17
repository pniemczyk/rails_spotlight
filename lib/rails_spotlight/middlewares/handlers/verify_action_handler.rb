# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class VerifyActionHandler < BaseActionHandler
        def execute; end

        private

        def text_response_body
          "Rails Spotlight is working!\nRails version: #{Rails.version}\nRails environment: #{Rails.env}"
        end

        def skip_project_validation?
          true
        end

        def json_response_body
          {
            params: request.params,
            body: request.body.read,
            content_type: request.content_type,
            request_method: request.request_method,
            version: request_spotlight_version,
            for_projects: request_for_projects,
            current_gem_version: ::RailsSpotlight::VERSION,
            action_cable_path: defined?(ActionCable) ? ActionCable&.server&.config&.mount_path : nil
          }
        end
      end
    end
  end
end
