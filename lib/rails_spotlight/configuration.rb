# frozen_string_literal: true

require 'yaml'
require 'erb'

module RailsSpotlight
  class Configuration
    DEFAULT_NOT_ENCODABLE_EVENT_VALUES = {
      'ActiveRecord' => ['ActiveRecord::ConnectionAdapters::AbstractAdapter'],
      'ActionDispatch' => ['ActionDispatch::Request', 'ActionDispatch::Response']
    }.freeze

    attr_reader :project_name, :source_path, :logger, :storage_path, :storage_pool_size, :middleware_skipped_paths,
                :not_encodable_event_values, :action_cable_mount_path

    def initialize(opts = {}) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      @project_name = opts[:project_name] || detect_project_name
      @source_path = opts[:source_path] || self.class.rails_root
      @logger = opts[:logger] || Logger.new(File.join(self.class.rails_root, 'log', 'rails_spotlight.log'))
      @storage_path = opts[:storage_path] || File.join(self.class.rails_root, 'tmp', 'data', 'rails_spotlight')
      @storage_pool_size = opts[:storage_pool_size] || 20
      @live_console_enabled = opts[:live_console_enabled] || true
      @request_completed_broadcast_enabled = opts[:request_completed_broadcast_enabled] || false
      @middleware_skipped_paths = opts[:middleware_skipped_paths] || []
      @not_encodable_event_values = DEFAULT_NOT_ENCODABLE_EVENT_VALUES.merge(opts[:not_encodable_event_values] || {})
      @auto_mount_action_cable = opts[:auto_mount_action_cable] || true
      @action_cable_mount_path = opts[:action_cable_mount_path] || '/cable'
    end

    def live_console_enabled
      @live_console_enabled && action_cable_present?
    end

    alias live_console_enabled? live_console_enabled

    def request_completed_broadcast_enabled
      @request_completed_broadcast_enabled && action_cable_present?
    end

    alias request_completed_broadcast_enabled? request_completed_broadcast_enabled

    def auto_mount_action_cable
      @auto_mount_action_cable && action_cable_present?
    end

    alias auto_mount_action_cable? auto_mount_action_cable

    def action_cable_present?
      defined?(ActionCable) && true
    end

    def self.load_config
      config_file = File.join(rails_root, 'config', 'rails_spotlight.yml')
      return new unless File.exist?(config_file)

      erb_result = ERB.new(File.read(config_file)).result
      config = YAML.safe_load(erb_result) || {}
      # Support older versions of Ruby and Rails
      opts = config.each_with_object({}) do |(key, value), memo|
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
