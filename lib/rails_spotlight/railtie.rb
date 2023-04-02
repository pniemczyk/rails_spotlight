# frozen_string_literal: true

require 'rails/railtie'

module RailsSpotlight
  class Railtie < ::Rails::Railtie
    initializer 'rails_spotlight.inject_middlewares' do
      insert_middleware unless Rails.env.production?
    end

    # initializer 'rails_spotlight.log_interceptor' do
    #   Rails.logger&.extend(LogInterceptor)
    # end
    #
    # initializer 'rails_spotlight.subscribe_to_notifications' do
    #   AppNotifications.subscribe
    # end

    def insert_middleware
      if defined? ActionDispatch::DebugExceptions
        app.middleware.insert_before ActionDispatch::DebugExceptions, RailsSpotlight::Middlewares::RequestHandler
      else
        app.middleware.use RailsSpotlight::Middlewares::RequestHandler
      end
    end

    def app
      Rails.application
    end
  end
end
