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
  # Rest of the configuration is required for ActionCable. It will be disabled automatically in when ActionCable is not available.
  # LIVE_CONSOLE_ENABLED from version 0.2.3 do not require ActionCable to be enabled.
  LIVE_CONSOLE_ENABLED: false
  # Experimental feature.
  REQUEST_COMPLETED_BROADCAST_ENABLED: false
  AUTO_MOUNT_ACTION_CABLE: false
  ACTION_CABLE_MOUNT_PATH: /cable
  BLOCK_EDITING_FILES: false
  BLOCK_EDITING_FILES_OUTSIDE_OF_THE_PROJECT: true
```

## Additional metrics

To enable additional rendering metrics like local variables, instance variables, params etc. add to your layout file:

```erb
<% if Rails.env.development? %>
  <%= RailsSpotlight::RenderViewReporter.report_rendered_view_locals(self, locals: local_assigns, params: params, skip_vars: %i[current_template], metadata: { just_test: 'Works' }) %>
<% end %>
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

