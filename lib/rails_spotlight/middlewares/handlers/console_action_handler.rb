# frozen_string_literal: true

require_relative '../../rails_command_executor'
module RailsSpotlight
  module Middlewares
    module Handlers
      class ConsoleActionHandler < BaseActionHandler
        def execute
          raise Forbidden.new('Console is disabled', code: :disabled_irb_console_settings) unless enabled?

          RailsSpotlight.config.logger && RailsSpotlight.config.logger.info("Executing command: #{command}") # rubocop:disable Style/SafeNavigation
          executor.execute(command)
        end

        private

        def executor = @executor ||= ::RailsSpotlight::RailsCommandExecutor.new
        def inspect_types = @inspect_types ||= body_fetch('inspect_types')
        def command = @command ||= body_fetch('command')

        def json_response_body
          return executor.result_as_json unless executor.execution_successful?

          { result: executor.result_as_json(inspect_types:) }
        end

        def enabled? = ::RailsSpotlight.config.irb_console_enabled?
      end
    end
  end
end
