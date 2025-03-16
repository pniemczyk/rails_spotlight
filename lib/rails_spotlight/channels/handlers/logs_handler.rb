# frozen_string_literal: true

module RailsSpotlight
  module Channels
    module Handlers
      class LogsHandler
        TYPE = 'logs'

        def initialize(data)
          @data = data
        end

        attr_reader :data

        def call
          return unless ::RailsSpotlight.config.cable_logs_enabled?
          return unless data['type'] == TYPE

          for_project = Array(data['project'])
          raise_project_mismatch_error!(for_project) if for_project.present? && !for_project.include?(project)

          { payload: data[:payload] }
        end

        def raise_project_mismatch_error!(for_project)
          raise ::RailsSpotlight::Channels::Handlers::ResponseError.new(
            "Project mismatch, Logs from #{for_project} project cannot be forwarded in #{project} project",
            code: :project_mismatch
          )
        end

        def project
          ::RailsSpotlight.config.project_name
        end
      end
    end
  end
end
