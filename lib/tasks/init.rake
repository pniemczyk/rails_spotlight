# frozen_string_literal: true

require 'rake'

namespace :rails_spotlight do # rubocop:disable Metrics/BlockLength
  desc 'Generate rails_spotlight configuration file'
  task generate_config: :environment do
    require 'fileutils'

    config_path = Rails.root.join('config', 'rails_spotlight.yml')

    default_config = <<~YAML
      # Default configuration for RailsSpotlight
      PROJECT_NAME: <%=Rails.application.class.respond_to?(:module_parent_name) ? Rails.application.class.module_parent_name : Rails.application.class.parent_name%>
      SOURCE_PATH: <%=Rails.root%>
      STORAGE_PATH: <%=Rails.root.join('tmp', 'data', 'rails_spotlight')%>
      STORAGE_POOL_SIZE: 20
      LOGGER: <%=Logger.new(Rails.root.join('log', 'rails_spotlight.log'))%>
      MIDDLEWARE_SKIPPED_PATHS: []
      NOT_ENCODABLE_EVENT_VALUES:
      # Rest of the configuration is required for ActionCable. It will be disabled automatically in when ActionCable is not available.
      LIVE_CONSOLE_ENABLED: true
      REQUEST_COMPLETED_BROADCAST_ENABLED: false
      AUTO_MOUNT_ACTION_CABLE: false
      ACTION_CABLE_MOUNT_PATH: /cable
      BLOCK_EDITING_FILES: false
      BLOCK_EDITING_FILES_OUTSIDE_OF_THE_PROJECT: true
    YAML

    if File.exist?(config_path)
      puts 'Config file already exists: config/rails_spotlight.yml'
    else
      FileUtils.mkdir_p(File.dirname(config_path))
      File.write(config_path, default_config)
      puts 'Created config file: config/rails_spotlight.yml'
    end
  end
end
