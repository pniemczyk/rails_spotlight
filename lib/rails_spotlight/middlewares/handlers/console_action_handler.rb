# frozen_string_literal: true

require_relative '../../rails_command_executor'
module RailsSpotlight
  module Middlewares
    module Handlers
      class ConsoleActionHandler < BaseActionHandler
        def execute
          RailsSpotlight.config.logger && RailsSpotlight.config.logger.info("Executing command: #{command}") # rubocop:disable Style/SafeNavigation
          executor.execute(command)
        end

        private

        def executor
          @executor ||= ::RailsSpotlight::RailsCommandExecutor.new
        end

        def inspect_types
          @inspect_types ||= body_fetch('inspect_types')
        end

        def command
          @command ||= body_fetch('command')
        end

        def json_response_body
          return executor.result_as_json unless executor.execution_successful?

          { result: executor.result_as_json(inspect_types: inspect_types) }
        end
      end
    end
  end
end
