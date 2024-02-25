# frozen_string_literal: true

require_relative '../rails_command_executor'
module RailsSpotlight
  module Channels
    class LiveConsoleChannel < ActionCable::Channel::Base
      def subscribed
        stream_from 'rails_spotlight_live_console_channel'
        publish({ message: "Welcome to the #{project} project Rails Spotlight Live Console" })
      end

      def unsubscribed
        # Any cleanup needed when channel is unsubscribed
      end

      def receive(data)
        command = data['command']
        inspect_types = data['inspect_types']
        for_project = data['project']
        return publish({ error: project_mismatch_message(for_project) }) if for_project.present? && for_project != project

        output = execute_command(command, inspect_types)
        publish(output)
      end

      private

      def project_mismatch_message(for_project)
        "Project mismatch, The command was intended for the #{for_project} project. This is #{project} project"
      end

      def publish(data)
        transmit(data.merge(project: project))
      end

      # TODO: add possibility to change project name via ENV variable or RailsSpotlight config
      def project
        ::RailsSpotlight.config.project_name
      end

      def executor
        @executor ||= ::RailsSpotlight::RailsCommandExecutor.new
      end

      def execute_command(command, inspect_types)
        RailsSpotlight.config.logger && RailsSpotlight.config.logger.info("Executing command: #{command}") # rubocop:disable Style/SafeNavigation

        executor.execute(command)
        if executor.execution_successful?
          {
            result: executor.result_as_json(inspect_types: inspect_types),
            project: ::RailsSpotlight.config.project_name
          }
        else
          executor.result_as_json.merge(project: ::RailsSpotlight.config.project_name)
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        { error: e.message }
      end
    end
  end
end
