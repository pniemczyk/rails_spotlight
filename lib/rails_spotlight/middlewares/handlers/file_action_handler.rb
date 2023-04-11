module RailsSpotlight
  module Middlewares
    module Handlers
      class FileActionHandler < BaseActionHandler
        def execute
          raise NotFound, 'File not found' unless path_valid?

          File.write(file_path, json_request_body.fetch('content')) if write_mode?
        rescue => e # rubocop:disable Style/RescueStandardError
          raise UnprocessableEntity, e.message
        end

        private

        def text_response_body
          File.read(file_path)
        end

        def json_response_body
          { source: text_response_body }
        end

        def write_mode?
          request_mode == 'write'
        end

        def request_mode
          @request_mode ||= json_request_body.fetch('mode') { 'read' }
        end

        def path_valid?
          File.exist?(file_path)
        end

        def file_path
          @file_path ||= Rails.root.join(json_request_body.fetch('file'))
        end
      end
    end
  end
end
