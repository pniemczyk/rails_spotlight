# frozen_string_literal: true

require 'json'
require 'tempfile'

module RailsSpotlight
  module Middlewares
    module Handlers
      class CodeAnalysisActionHandler < BaseActionHandler
        def skip_project_validation? = true

        def execute
          raise Forbidden.new('Code analysis is disabled', code: :disabled_rubocop_settings) unless enabled?
          raise UnprocessableEntity.new('Please add rubocop to your project', code: :rubocop_not_installed) unless rubocop_installed?
        end

        private

        def rubocop_installed?
          Gem::Specification.find_all_by_name('rubocop').any?
        rescue Gem::LoadError
          false
        end

        def json_response_body # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          require 'rubocop'

          # Create a temporary file to hold the source code
          tempfile = Tempfile.new(['source', '.rb'])
          tempfile.write(source)
          tempfile.rewind

          # Create a temporary file to capture the RuboCop output
          output_file = Tempfile.new(['rubocop_output', '.json'])

          # Define RuboCop options
          options = {
            formatters: [['json', output_file.path]],
            cache: false,
            safe: true
          }

          options[:autocorrect] = variant == :autofix

          # Check for custom .rubocop.yml configuration
          config_file = ::RailsSpotlight.config.rubocop_config_path || File.join(RailsSpotlight::Configuration.rails_root, '.rubocop.yml')

          # Run RuboCop with appropriate options
          config_store = RuboCop::ConfigStore.new
          config_store.options_config = config_file if File.exist?(config_file)
          runner = RuboCop::Runner.new(options, config_store)

          begin
            runner.run([tempfile.path])

            # Read the corrected source
            tempfile.rewind
            corrected_source = File.read(tempfile.path)

            # Read the RuboCop analysis result from the output file
            output_file.rewind
            analysis_result = JSON.parse(output_file.read)

            {
              source: variant == :autofix ? corrected_source : source,
              analysis_result:,
              variant:
            }
          ensure
            # Close and unlink the tempfile
            tempfile.close
            tempfile.unlink
            output_file.close
            output_file.unlink
          end
        end

        def source = @source ||= body_fetch('source')
        def variant = @variant ||= body_fetch('variant', 'check').to_sym
        def enabled? = ::RailsSpotlight.config.rubocop_enabled?
      end
    end
  end
end
