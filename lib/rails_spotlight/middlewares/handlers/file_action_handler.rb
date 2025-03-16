# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class FileActionHandler < BaseActionHandler
        def execute
          raise Forbidden.new('File manager is disabled', code: :disabled_file_manager_settings) unless enabled?
          raise NotFound.new('File not found', code: :file_not_found) unless path_valid?

          begin
            write_mode? ? try_to_update_file : File.read(file_path)
          rescue => e # rubocop:disable Style/RescueStandardError
            raise UnprocessableEntity.new(e.message, code: write_mode? ? :file_update_error : :file_read_error)
          end
        end

        private

        def text_response_body = File.read(file_path)
        def new_content = body_fetch('content')

        def json_response_body
          {
            source: text_response_body,
            changed: write_mode?,
            in_project: file_in_project?,
            relative_path: Pathname.new(file_path).relative_path_from(::RailsSpotlight.config.rails_root).to_s,
            root_path: ::RailsSpotlight.config.rails_root
          }.merge(write_mode? ? { new_content: } : {})
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

        def write_mode? = request_mode == 'write'
        def request_mode = @request_mode ||= body_fetch('mode', 'read')
        def path_valid? = File.exist?(file_path)

        def file_path
          @file_path ||= if path_file_in_project?
                           original_file_path
                         elsif file_in_project?
                           File.join(::RailsSpotlight.config.rails_root, original_file_path)
                         elsif file_in_project_app_dir?
                           File.join(::RailsSpotlight.config.rails_root, 'app', original_file_path)
                         elsif file_in_project_views_dir?
                           File.join(::RailsSpotlight.config.rails_root, 'app', 'views', original_file_path)
                         else # rubocop:disable Lint/DuplicateBranch
                           original_file_path
                         end
        end

        def original_file_path = @original_file_path ||= body_fetch('file')

        def path_file_in_project? = @path_file_in_project ||= original_file_path.start_with?(::RailsSpotlight.config.rails_root)
        def file_in_project? = File.exist?(File.join(::RailsSpotlight.config.rails_root, original_file_path))
        def file_in_project_app_dir? = File.exist?(File.join(::RailsSpotlight.config.rails_root, 'app', original_file_path))
        def file_in_project_views_dir? = File.exist?(File.join(::RailsSpotlight.config.rails_root, 'app', 'views', original_file_path))
        def file_outside_project? = !file_in_project? && File.exist?(original_file_path)

        def editing_outside_project_file_is_blocked?(file_path)
          return false unless file_outside_project?
          return false unless block_editing_files_outside_of_the_project?

          !file_path.start_with?(::RailsSpotlight.config.rails_root)
        end

        def block_editing_files? = ::RailsSpotlight.config.block_editing_files
        def block_editing_files_outside_of_the_project? = ::RailsSpotlight.config.block_editing_files_outside_of_the_project
        def enabled? = ::RailsSpotlight.config.file_manager_enabled
      end
    end
  end
end
