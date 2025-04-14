# frozen_string_literal: true

require 'yaml'
require 'erb'

module RailsSpotlight
  class Configuration
    DEFAULT_NOT_ENCODABLE_EVENT_VALUES = {
      'ActiveRecord' => [
        'ActiveRecord::ConnectionAdapters::AbstractAdapter',
        'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter',
        'ActiveRecord::ConnectionAdapters::RealTransaction',
        'ActiveRecord::Transaction',
        'ActiveRecord::SchemaMigration'
      ],
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

    attr_reader :enabled, :project_name, :source_path, :logger, :storage_path, :storage_pool_size, :middleware_skipped_paths,
                :not_encodable_event_values, :cable_mount_path, :logs_enabled,
                :file_manager_enabled, :block_editing_files, :block_editing_files_outside_of_the_project, :skip_rendered_ivars,
                :directory_index_ignore, :rubocop_enabled, :rubocop_config_path, :use_cable, :default_rs_src,
                :form_js_execution_token, :sql_console_enabled, :irb_console_enabled, :data_access_token

    def initialize(opts = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
      @enabled = bool_val(:enabled, opts, default: false)
      @logs_enabled = bool_val(:logs_enabled, opts, default: true)
      @project_name = opts[:project_name] || detect_project_name
      @source_path = opts[:source_path] || self.class.rails_root
      @logger = opts[:logger] || Logger.new(File.join(self.class.rails_root, 'log', 'rails_spotlight.log'))
      @storage_path = opts[:storage_path] || File.join(self.class.rails_root, 'tmp', 'data', 'rails_spotlight')
      @storage_pool_size = opts[:storage_pool_size] || 20
      @cable_console_enabled = bool_val(:cable_console_enabled, opts)
      @request_completed_broadcast_enabled = bool_val(:request_completed_broadcast_enabled, opts)
      @middleware_skipped_paths = opts[:middleware_skipped_paths] || []
      @not_encodable_event_values = DEFAULT_NOT_ENCODABLE_EVENT_VALUES.merge(opts[:not_encodable_event_values] || {})
      @use_cable = bool_val(:use_cable, opts)
      @auto_mount_cable = bool_val(:auto_mount_cable, opts)
      @cable_mount_path = opts[:cable_mount_path] || '/cable'
      @block_editing_files = bool_val(:block_editing_files, opts)
      @block_editing_files_outside_of_the_project = bool_val(:block_editing_files_outside_of_the_project, opts, default: true)
      @file_manager_enabled = bool_val(:file_manager_enabled, opts, default: true)
      @skip_rendered_ivars = SKIP_RENDERED_IVARS + (opts[:skip_rendered_ivars] || []).map(&:to_sym)
      @directory_index_ignore = opts[:directory_index_ignore] || DEFAULT_DIRECTORY_INDEX_IGNORE
      @rubocop_enabled = bool_val(:rubocop_enabled, opts, default: true)
      @rubocop_config_path = opts[:rubocop_config_path] ? File.join(self.class.rails_root, opts[:rubocop_config_path]) : nil
      @cable_logs_enabled = bool_val(:cable_logs_enabled, opts)
      @default_rs_src = opts[:default_rs_src] || 'default'
      @form_js_execution_token = opts[:form_js_execution_token] || Digest::MD5.hexdigest(detect_project_name)
      @sql_console_enabled = bool_val(:sql_console_enabled, opts, default: true)
      @irb_console_enabled = bool_val(:irb_console_enabled, opts, default: true)
      @data_access_token = opts[:data_access_token].present? ? opts[:data_access_token] : nil
    end

    def cable_console_enabled = @cable_console_enabled && use_cable && action_cable_present?
    def cable_logs_enabled = @cable_logs_enabled && use_cable && action_cable_present?
    def request_completed_broadcast_enabled = @request_completed_broadcast_enabled && use_cable && action_cable_present?
    def auto_mount_cable = @auto_mount_cable && use_cable && action_cable_present?
    def action_cable_present? = defined?(ActionCable) && true

    alias enabled? enabled
    alias logs_enabled? logs_enabled
    alias cable_console_enabled? cable_console_enabled
    alias cable_logs_enabled? cable_logs_enabled
    alias use_cable? use_cable
    alias request_completed_broadcast_enabled? request_completed_broadcast_enabled
    alias auto_mount_cable? auto_mount_cable
    alias file_manager_enabled? file_manager_enabled
    alias rubocop_enabled? rubocop_enabled
    alias sql_console_enabled? sql_console_enabled
    alias irb_console_enabled? irb_console_enabled

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

    def self.rails_root = @rails_root ||= (Rails.root.to_s.presence || Dir.pwd).freeze
    def rails_root = self.class.rails_root

    private

    def detect_project_name
      return ENV['RAILS_SPOTLIGHT_PROJECT'] if ENV['RAILS_SPOTLIGHT_PROJECT'].present?

      app_class.respond_to?(:module_parent_name) ? app_class.module_parent_name : app_class.parent_name
    end

    def app_class = @app_class ||= Rails.application.class
    def true?(value) = [true, 'true', 1, '1'].include?(value)
    def bool_val(key, opts, default: false) = opts[key].nil? ? default : true?(opts[key])
  end
end
