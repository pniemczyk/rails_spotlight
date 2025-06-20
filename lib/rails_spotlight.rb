# frozen_string_literal: true

module RailsSpotlight
  autoload :VERSION,               'rails_spotlight/version'
  autoload :Configuration,         'rails_spotlight/configuration'
  autoload :Storage,               'rails_spotlight/storage'
  autoload :Event,                 'rails_spotlight/event'
  autoload :AppRequest,            'rails_spotlight/app_request'
  autoload :Middlewares,           'rails_spotlight/middlewares'
  autoload :LogInterceptor,        'rails_spotlight/log_interceptor'
  autoload :NotificationExtension, 'rails_spotlight/notification_extension'
  autoload :AppNotifications,      'rails_spotlight/app_notifications'
  autoload :Utils,                 'rails_spotlight/utils'
  autoload :RenderViewReporter,    'rails_spotlight/render_view_reporter'


  class << self
    def config
      @config ||= Configuration.load_config
    end
  end

  autoload :Channels, 'rails_spotlight/channels'
end

require_relative 'rails_spotlight/railtie'

if defined?(Rake)
  spec = Gem::Specification.find_by_name 'rails_spotlight'
  load "#{spec.gem_dir}/lib/tasks/init.rake"
end
