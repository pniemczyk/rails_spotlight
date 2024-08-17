# frozen_string_literal: true

require 'yaml'
require 'erb'

module RailsSpotlight
  class Configuration
    DEFAULT_NOT_ENCODABLE_EVENT_VALUES = {
      'ActiveRecord' => ['ActiveRecord::ConnectionAdapters::AbstractAdapter'],
      'ActionDispatch' => ['ActionDispatch::Request', 'ActionDispatch::Response']
    }.freeze

    DEFAULT_DIRECTORY_INDEX_IGNORE = %w[
      /.git **/*.lock **/.DS_Store /app/assets/images/** /app/assets/fonts/** /app/assets/builds/** **/.keep
    ].freeze

    SKIP_RENDERED_IVARS = %i[
      @_routes
      @_config
      @view_renderer
      @lookup_context
      @_assigns
      @_controller
      @_request
      @_default_form_builder
      @view_flow
      @output_buffer
      @virtual_path
      @tag_builder
      @assets_environment
      @asset_resolver_strategies
      @_main_app
      @_devise_route_context
      @devise_mapping
    ].freeze

    attr_reader :project_name, :source_path, :logger, :storage_path, :storage_pool_size, :middleware_skipped_paths,
                :not_encodable_event_values, :action_cable_mount_path,
                :block_editing_files, :block_editing_files_outside_of_the_project, :skip_rendered_ivars,
                :directory_index_ignore, :rubocop_config_path, :use_action_cable, :default_rs_src,
                :form_js_execution_token

    def initialize(opts = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
      @project_name = opts[:project_name] || detect_project_name
      @source_path = opts[:source_path] || self.class.rails_root
      @logger = opts[:logger] || Logger.new(File.join(self.class.rails_root, 'log', 'rails_spotlight.log'))
      @storage_path = opts[:storage_path] || File.join(self.class.rails_root, 'tmp', 'data', 'rails_spotlight')
      @storage_pool_size = opts[:storage_pool_size] || 20
      @live_console_enabled = opts[:live_console_enabled].nil? ? false : true?(opts[:live_console_enabled])
      @request_completed_broadcast_enabled = opts[:request_completed_broadcast_enabled].nil? ? false : true?(opts[:request_completed_broadcast_enabled])
      @middleware_skipped_paths = opts[:middleware_skipped_paths] || []
      @not_encodable_event_values = DEFAULT_NOT_ENCODABLE_EVENT_VALUES.merge(opts[:not_encodable_event_values] || {})
      @use_action_cable = opts[:use_action_cable].nil? ? false : true?(opts[:use_action_cable])
      @auto_mount_action_cable = opts[:auto_mount_action_cable].nil? ? false : true?(opts[:auto_mount_action_cable])
      @action_cable_mount_path = opts[:action_cable_mount_path] || '/cable'
      @block_editing_files = opts[:block_editing_files].nil? ? false : true?(opts[:block_editing_files])
      @block_editing_files_outside_of_the_project = opts[:block_editing_files_outside_of_the_project].nil? ? true : true?(opts[:block_editing_files_outside_of_the_project])
      @skip_rendered_ivars = SKIP_RENDERED_IVARS + (opts[:skip_rendered_ivars] || []).map(&:to_sym)
      @directory_index_ignore = opts[:directory_index_ignore] || DEFAULT_DIRECTORY_INDEX_IGNORE
      @rubocop_config_path = opts[:rubocop_config_path] ? File.join(self.class.rails_root, opts[:rubocop_config_path]) : nil
      @live_logs_enabled = opts[:live_logs_enabled].nil? ? false : true?(opts[:live_logs_enabled])
      @default_rs_src = opts[:default_rs_src] || 'default'
      @form_js_execution_token = opts[:form_js_execution_token] || Digest::MD5.hexdigest(detect_project_name)
    end

    def live_console_enabled
      @live_console_enabled && use_action_cable && action_cable_present?
    end

    def live_logs_enabled
      @live_logs_enabled && use_action_cable && action_cable_present?
    end

    alias live_console_enabled? live_console_enabled
    alias live_logs_enabled? live_logs_enabled

    def request_completed_broadcast_enabled
      @request_completed_broadcast_enabled && use_action_cable && action_cable_present?
    end

    alias request_completed_broadcast_enabled? request_completed_broadcast_enabled

    def auto_mount_action_cable
      @auto_mount_action_cable && use_action_cable && action_cable_present?
    end

    alias auto_mount_action_cable? auto_mount_action_cable

    def action_cable_present?
      defined?(ActionCable) && true
    end

    def self.load_config
      config_file = File.join(rails_root, 'config', 'rails_spotlight.yml')
      return new unless File.exist?(config_file)

      erb_result = ERB.new(File.read(config_file)).result
      data = YAML.safe_load(erb_result) || {}

      # Support older versions of Ruby and Rails
      opts = data.each_with_object({}) do |(key, value), memo|
        new_key = key.is_a?(String) ? key.downcase.to_sym : key
        memo[new_key] = value
      end

      new(opts)
    end

    def self.rails_root
      @rails_root ||= (Rails.root.to_s.presence || Dir.pwd).freeze
    end

    def rails_root
      self.class.rails_root
    end

    private

    def true?(value)
      [true, 'true', 1, '1'].include?(value)
    end

    def detect_project_name
      return ENV['RAILS_SPOTLIGHT_PROJECT'] if ENV['RAILS_SPOTLIGHT_PROJECT'].present?

      if app_class.respond_to?(:module_parent_name)
        app_class.module_parent_name
      else
        app_class.parent_name
      end
    end

    def app_class
      @app_class ||= Rails.application.class
    end
  end
end
