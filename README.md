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
  # Rest of the configuration is required for ActionCable. It will be disabled automatically in when ActionCable is not available.
  LIVE_CONSOLE_ENABLED: true
  REQUEST_COMPLETED_BROADCAST_ENABLED: false
  AUTO_MOUNT_ACTION_CABLE: true
  ACTION_CABLE_MOUNT_PATH: /cable
```

## Testing

To run tests for all versions of Rails and Ruby, run:

```bash
docker-compose up
```

## Usage

Gem is created for the Chrome extension [Rails Spotlight](https://chrome.google.com/webstore/detail/rails-spotlight/kfacifkandemkdemkliponofajohhnbp?hl=en-US), but it can be used for any purpose.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

