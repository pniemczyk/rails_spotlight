# frozen_string_literal: true

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

        output = execute_command(command, { inspect_types: inspect_types })
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

      def execute_command(command, opts = {})
        output_stream = StringIO.new # Create a new StringIO object to capture output
        inspect_types = opts[:inspect_types]
        result = nil

        begin
          original_stdout = $stdout
          $stdout = output_stream
          result = eval(command) # rubocop:disable Security/Eval
        ensure
          $stdout = original_stdout
        end

        # result = eval(command)
        {
          result: {
            inspect: result.inspect,
            raw: result,
            type: result.class.name,
            types: result_inspect_types(inspect_types, result),
            console: output_stream.string
          }
        }
      rescue StandardError => e
        { error: e.message }
      end

      def result_inspect_types(inspect_types, result)
        return {} unless inspect_types

        {
          root: result.class.name,
          items: result_types_items(result)
        }
      end

      def result_types_items(result)
        case result
        when Array
          # Create a hash with indices as keys and class names as values
          result.each_with_index.to_h { |element, index| [index.to_s, element.class.name] }
        when Hash
          # Create a hash with string keys and class names as values
          result.transform_keys(&:to_s).transform_values { |value| value.class.name }
        else
          # For non-collection types, there are no items
          {}
        end
      end
    end
  end
end
