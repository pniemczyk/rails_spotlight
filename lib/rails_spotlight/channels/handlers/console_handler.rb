# frozen_string_literal: true

require_relative '../../rails_command_executor'

module RailsSpotlight
  module Channels
    module Handlers
      class ConsoleHandler
        TYPE = 'console'

        def initialize(data)
          @data = data
        end

        attr_reader :data

        def call
          return unless ::RailsSpotlight.config.cable_logs_enabled?
          return unless data['type'] == TYPE

          command = data['command']
          inspect_types = data['inspect_types']
          for_project = Array(data['project'])

          raise_project_mismatch_error!(for_project) if for_project.present? && !for_project.include?(project)

          execute_command(command, inspect_types)
        end

        def executor
          @executor ||= ::RailsSpotlight::RailsCommandExecutor.new
        end

        def raise_project_mismatch_error!(for_project)
          raise ::RailsSpotlight::Channels::Handlers::ResponseError.new(
            "Project mismatch, The command was intended for the #{for_project} project. This is #{project} project",
            code: :project_mismatch
          )
        end

        def execute_command(command, inspect_types)
          RailsSpotlight.config.logger && RailsSpotlight.config.logger.info("Executing command: #{command}") # rubocop:disable Style/SafeNavigation

          executor.execute(command)
          if executor.execution_successful?
            {
              payload: { result: executor.result_as_json(inspect_types:) }
            }
          else
            {
              payload: { failed: executor.result_as_json }
            }
          end
        rescue => e # rubocop:disable Style/RescueStandardError
          { error: e.message }
        end

        def project
          ::RailsSpotlight.config.project_name
        end
      end
    end
  end
end
