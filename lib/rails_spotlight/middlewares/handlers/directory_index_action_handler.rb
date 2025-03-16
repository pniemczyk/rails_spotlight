# frozen_string_literal: true

require 'json'
require 'find'
require 'pathname'

module RailsSpotlight
  module Middlewares
    module Handlers
      class DirectoryIndexActionHandler < BaseActionHandler
        def execute
          raise Forbidden.new('File manager is disabled', code: :disabled_file_manager_settings) unless enabled?

          @result = begin
            directory_to_json(::RailsSpotlight.config.rails_root)
          rescue => e # rubocop:disable Style/RescueStandardError
            raise UnprocessableEntity.new(e.message, code: :directory_index_error)
          end
        end

        private

        attr_reader :result

        def directory_to_json(path) # rubocop:disable Metrics/CyclomaticComplexity
          relative_path = Pathname.new(path).relative_path_from(::RailsSpotlight.config.rails_root).to_s
          return nil if ignored?(relative_path)

          entry = {
            name: File.basename(path),
            path: relative_path,
            dir: File.directory?(path),
            children: []
          }

          if entry[:dir]
            children = sort_children(Dir.children(path), path)
            children.each do |child|
              child_path = File.join(path, child)
              child_entry = directory_to_json(child_path)
              entry[:children] << child_entry if child_entry
            end
          end

          return entry unless entry[:dir]
          return entry unless entry[:children].empty?

          show_empty_directories ? entry : nil
        end

        def sort_children(children, parent_path)
          if sort_folders_first
            children.sort_by do |child|
              child_path = File.join(parent_path, child)
              [File.directory?(child_path) ? 0 : 1, child.downcase]
            end
          else
            children.sort_by(&:downcase)
          end
        end

        def ignore = @ignore ||= body_fetch('ignore', [])
        def sort_folders_first = @sort_folders_first ||= body_fetch('sort_folders_first', true)
        def omnit_gitignore = @omnit_gitignore ||= body_fetch('omnit_gitignore', false)
        def ignore_patterns = @ignore_patterns ||= ignore + ::RailsSpotlight.config.directory_index_ignore + (omnit_gitignore ? [] : gitignore_patterns)
        def gitignore_file = @gitignore_file ||= File.join(::RailsSpotlight.config.rails_root, '.gitignore')
        def show_empty_directories = @show_empty_directories ||= body_fetch('show_empty_directories', false)

        def gitignore_patterns
          @gitignore_patterns ||= if File.exist?(gitignore_file)
                                    File.readlines(gitignore_file).map do |line|
                                      line.strip!
                                      next if line.empty? || line.start_with?('#') || line.start_with?('!')

                                      line
                                    end.compact
                                  else
                                    []
                                  end
        end

        def ignored?(path)
          return false if path == '.'

          ignore_patterns.any? do |pattern|
            File.fnmatch?(pattern, "/#{path}", File::FNM_PATHNAME | File::FNM_DOTMATCH)
          end
        end

        def json_response_body
          {
            root_path: ::RailsSpotlight.config.rails_root,
            result:
          }
        end

        def enabled? = ::RailsSpotlight.config.file_manager_enabled
      end
    end
  end
end
