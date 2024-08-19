# frozen_string_literal: true

require 'rake'

namespace :rails_spotlight do # rubocop:disable Metrics/BlockLength
  desc 'Generate rails_spotlight configuration file'
  task generate_config: :environment do # rubocop:disable Metrics/BlockLength
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
      SKIP_RENDERED_IVARS: []
      BLOCK_EDITING_FILES: false
      BLOCK_EDITING_FILES_OUTSIDE_OF_THE_PROJECT: true
      DIRECTORY_INDEX_IGNORE: ['/.git', '**/*.lock', '**/.DS_Store', '/app/assets/images/**', '/app/assets/fonts/**', '/app/assets/builds/**']
      RUBOCOP_CONFIG_PATH: '.rubocop.yml'
      # Rest of the configuration is required for ActionCable. It will be disabled automatically in when ActionCable is not available.
      AUTO_MOUNT_ACTION_CABLE: false
      ACTION_CABLE_MOUNT_PATH: /cable
      # Required for all action cable features
      USE_ACTION_CABLE: false
      LIVE_CONSOLE_ENABLED: false
      # Experimental feature.
      REQUEST_COMPLETED_BROADCAST_ENABLED: false
      LIVE_LOGS_ENABLED: false
      DEFAULT_RS_SRC: default
      FORM_JS_EXECUTION_TOKEN: <%= Digest::MD5.hexdigest(Rails.application.class.respond_to?(:module_parent_name) ? Rails.application.class.module_parent_name : Rails.application.class.parent_name)%>
    YAML

    if File.exist?(config_path)
      puts 'Config file already exists: config/rails_spotlight.yml'
    else
      FileUtils.mkdir_p(File.dirname(config_path))
      File.write(config_path, default_config)
      puts 'Created config file: config/rails_spotlight.yml'
    end
  end

  desc "Generate rails_spotlight JavaScript ERB partial for application layout to allow injecting JS code from the extension"
  task inject_js_partial: :environment do
    # Define the partial name and path
    partial_name = "_rails_spotlight_extension_js.html.erb"
    partial_path = "app/views/layouts/#{partial_name}"

    # Define the JavaScript code
    js_code = <<~JS
      <script>
        try {
          function executeScriptFromMessage(msg) {
            if (msg.token === "<%=::RailsSpotlight.config.form_js_execution_token%>") {
              try {
                const func = new Function(msg.code);
                func();
                return {status: 'Executed'};
              } catch (e) {
                return {status: 'Error', error: e};
              }
            } else {
              return {status: 'Error', error: 'Invalid token provided, script execution aborted.'};
            }
          }

          window.addEventListener('message', (event) => {
            if (event.data && event.data.type === 'RAILS_SPOTLIGHT_EXTENSION_JS_EXECUTION') {
              var result = executeScriptFromMessage(event.data);
              if (event.data.debug) {
                console.log('Script execution result:', result);
              }
            }
          });
        } catch (e) {
          console.error('Error initializing the RAILS_SPOTLIGHT_EXTENSION_JS_EXECUTION script listener:', e);
        }
      </script>
    JS

    # Generate the ERB partial
    File.write(partial_path, js_code)
    puts "Partial created: #{partial_path}"

    layout_file = Dir.glob('app/views/layouts/application.html.{erb,slim,haml}').first
    layout_format = layout_file ? layout_file.split('.').last : 'erb'

    if layout_file
      puts "Detected layout file: #{layout_file}"
      puts 'Please add the following line to your layout file at the appropriate place:'
    else
      puts 'No application layout file detected.'
      puts 'Please manually add the following line to your application layout file:'
    end

    case layout_format
    when 'slim'
      puts "- if Rails.env.development?\n  = render 'layouts/#{partial_name.split('.').first}'"
    when 'haml'
      puts "- if Rails.env.development?\n  = render 'layouts/#{partial_name.split('.').first}'"
    else
      puts "<% if Rails.env.development? %>\n  <%= render 'layouts/#{partial_name.split('.').first}' %>\n<% end %>"
    end
  end
end
