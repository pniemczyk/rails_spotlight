# frozen_string_literal: true

require_relative '../../rails_command_executor'
module RailsSpotlight
  module Middlewares
    module Handlers
      class ConsoleActionHandler < BaseActionHandler
        def execute
          validate_project!

          RailsSpotlight.config.logger && RailsSpotlight.config.logger.info("Executing command: #{command}") # rubocop:disable Style/SafeNavigation
          executor.execute(command)
        end

        private

        def validate_project!
          return if for_project.blank?
          return if for_project.include?(::RailsSpotlight.config.project_name)

          raise UnprocessableEntity, "Check your connection settings the current command is not allowed to be executed on the #{::RailsSpotlight.config.project_name} project"
        end

        def executor
          @executor ||= ::RailsSpotlight::RailsCommandExecutor.new
        end

        def inspect_types
          @inspect_types ||= json_request_body.fetch('inspect_types')
        end

        def command
          @command ||= json_request_body.fetch('command')
        end

        def for_project
          @for_project ||= json_request_body['project']
        end

        def json_response_body
          executor.result_as_json(inspect_types: inspect_types)
                  .merge(project: ::RailsSpotlight.config.project_name)
        end
      end
    end
  end
end
