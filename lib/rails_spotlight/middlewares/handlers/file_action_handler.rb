# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class FileActionHandler < BaseActionHandler
        def execute
          raise NotFound, 'File not found' unless path_valid?

          if write_mode?
            try_to_update_file
          else
            File.read(file_path)
          end
        rescue => e # rubocop:disable Style/RescueStandardError
          raise UnprocessableEntity, e.message
        end

        private

        def text_response_body
          File.read(file_path)
        end

        def new_content
          json_request_body.fetch('content')
        end

        def json_response_body
          {
            source: text_response_body,
            changed: write_mode?,
            project: ::RailsSpotlight.config.project_name
          }.merge(write_mode? ? { new_content: new_content } : {})
        end

        def write_mode?
          request_mode == 'write'
        end

        def try_to_update_file
          raise UnprocessableEntity, editing_files_block_msg if block_editing_files?
          raise UnprocessableEntity, editing_files_blocked_err_msg if editing_outside_project_file_is_blocked?(file_path)

          RailsSpotlight.config.logger && RailsSpotlight.config.logger.info("Updating file: #{file_path}") # rubocop:disable Style/SafeNavigation
          File.write(file_path, new_content)
        end

        def editing_files_block_msg
          'Editing files is blocked. Please check the Rails spotlight BLOCK_EDITING_FILES configuration.'
        end

        def editing_files_blocked_err_msg
          'Editing files is blocked. Please check the Rails spotlight BLOCK_EDITING_FILES_OUTSIDE_OF_THE_PROJECT configuration.'
        end

        def request_mode
          @request_mode ||= json_request_body.fetch('mode', 'read')
        end

        def path_valid?
          File.exist?(file_path)
        end

        def file_path
          @file_path ||= if path_file_in_project?
                           original_file_path
                         elsif file_in_project?
                           File.join(::RailsSpotlight.config.rails_root, original_file_path)
                         else # rubocop:disable Lint/DuplicateBranch
                           original_file_path
                         end
        end

        def original_file_path
          @original_file_path ||= json_request_body.fetch('file')
        end

        def path_file_in_project?
          @path_file_in_project ||= original_file_path.start_with?(::RailsSpotlight.config.rails_root)
        end

        def file_in_project?
          File.exist?(File.join(::RailsSpotlight.config.rails_root, original_file_path))
        end

        def file_outside_project?
          !file_in_project? && File.exist?(original_file_path)
        end

        def editing_outside_project_file_is_blocked?(file_path)
          return false unless file_outside_project?
          return false unless block_editing_files_outside_of_the_project?

          !file_path.start_with?(::RailsSpotlight.config.rails_root)
        end

        def block_editing_files?
          ::RailsSpotlight.config.block_editing_files
        end

        def block_editing_files_outside_of_the_project?
          ::RailsSpotlight.config.block_editing_files_outside_of_the_project
        end
      end
    end
  end
end
