# RailsSpotlight

Chrome extension [Rails Spotlight](https://chrome.google.com/webstore/detail/rails-spotlight/kfacifkandemkdemkliponofajohhnbp?hl=en-US).

## Support for

* Rails 5+
* Ruby 2.6+

## Installation

Add this line to your application's Gemfile:

```ruby
group :development do
  gem 'rails_spotlight'
end
```

## Configuration

Generate configuration file by running:

```bash
rails rails_spotlight:generate_config 
```

file will be created in `config/rails_spotlight.yml`

### Configuration options

```yaml
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
```

## Additional metrics

To enable additional rendering metrics like local variables, instance variables, params etc. add to your layout file:

```erb
<% if Rails.env.development? %>
  <%= RailsSpotlight::RenderViewReporter.report_rendered_view_locals(self, locals: local_assigns, params: params, skip_vars: %i[current_template], metadata: { just_test: 'Works' }) %>
<% end %>
```

## Experimental features
Live logs requires action cable to be enabled. 

USE_ACTION_CABLE: true
LIVE_LOGS_ENABLED: true

When you want to use different sources for the cable logs you need to update `cable.yml` file. 

```yaml
development:
  adapter: redis
  url: redis://localhost:6379/1
```
**Note:** Redis is required for live logs. so just add it to your Gemfile and run `bundle install`

modify yor `development.rb` file 

```ruby
config.action_cable.allowed_request_origins = ['chrome-extension://chjfnpmbgdbipfogflkhleaceacndaop' ]
```

Now just run your servers with environment variable RS_SRC=my_source_name
like `RS_SRC=sidekiq bundle exec sidekiq -C config/sidekiq.yml`
or `RS_SRC=web bundle exec puma -C config/puma.rb`

---

Forms (Filling forms with scenarios)

To be able use full potential of the forms you need to generate partial that helps with js code injection.

Just use `rails rails_spotlight:inject_js_partial` and inject partial to your layout file as instructed in past generation message.
setup your `FORM_JS_EXECUTION_TOKEN` or use pregnerated one in your extension settings.

# Advanced log configuration 
You can add to your Initializers `config/initializers/rails_spotlight.rb` file with the additional configuration for the logger.

```ruby
  unless Rails.env.production?
    # Publish logs to the spotlight (only when implementation is based on the Rails.logger)
    defined?(Logger) && Logger&.extend(RailsSpotlight::LogInterceptor)
    # Publish Hutch logs to the spotlight
    defined?(Hutch::Logging) && Hutch::Logging.logger&.extend(RailsSpotlight::LogInterceptor)
  end
```


## Troubleshooting

Known issue:

Authentication error when using: 
  - Specific authentication method and action cable
  - AUTO_MOUNT_ACTION_CABLE: true

Solution:
  - Set AUTO_MOUNT_ACTION_CABLE: false
  - Add manually `mount ActionCable.server => '/cable'` to `config/routes.rb` with proper authentication method

---

Requests crash when **ActionCable settings** -> **Use action cable for meta requests (required for Safari)**  is on

Solution:
  - Switch flag off
  - REQUEST_COMPLETED_BROADCAST_ENABLED: false

## Testing

To run tests for all versions of Rails and Ruby, run:

```bash
docker-compose up
```

## Usage

Gem is created for the Chrome extension [Rails Spotlight](https://chrome.google.com/webstore/detail/rails-spotlight/kfacifkandemkdemkliponofajohhnbp?hl=en-US), but it can be used for any purpose.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

