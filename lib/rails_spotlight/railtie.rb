# frozen_string_literal: true

require 'rails/railtie'
require_relative 'log_interceptor'

module RailsSpotlight
  class Railtie < ::Rails::Railtie
    initializer 'rails_spotlight.inject_middlewares' do
      insert_base_middlewares unless Rails.env.production?
    end

    initializer 'rails_spotlight.log_interceptor' do
      unless Rails.env.production?
        Rails.logger&.extend(LogInterceptor)
        defined?(Sidekiq::Logger) && Sidekiq.logger&.extend(LogInterceptor)
      end
    end

    initializer 'rails_spotlight.subscribe_to_notifications' do
      AppNotifications.subscribe unless Rails.env.production?
    end

    initializer 'rails_spotlight.action_cable_setup' do
      insert_action_cable_helpers unless Rails.env.production?
    end

    def insert_action_cable_helpers
      return unless ::RailsSpotlight.config.action_cable_present?

      app.config.after_initialize do
        update_actioncable_allowed_request_origins!

        require 'rails_spotlight/channels/spotlight_channel' if ::RailsSpotlight.config.request_completed_broadcast_enabled?

        app.routes.draw { mount ActionCable.server => ::RailsSpotlight.config.action_cable_mount_path || '/cable' } if ::RailsSpotlight.config.auto_mount_action_cable?
      end
    end

    def update_actioncable_allowed_request_origins!
      existing_origins = Array(app.config.action_cable.allowed_request_origins)
      app.config.action_cable.allowed_request_origins = existing_origins | [%r{\Achrome-extension://.*\z}]
    end

    def insert_base_middlewares
      app.middleware.use ::RailsSpotlight::Middlewares::RequestHandler

      if defined? ActionDispatch::DebugExceptions
        app.middleware.insert_before ActionDispatch::DebugExceptions, ::RailsSpotlight::Middlewares::HeaderMarker, app.config
      else
        app.middleware.use ::RailsSpotlight::Middlewares::HeaderMarker, app.config
      end

      app.middleware.use ::RailsSpotlight::Middlewares::MainRequestHandler

      return unless ::RailsSpotlight.config.request_completed_broadcast_enabled?

      # app.middleware.insert_after ::RailsSpotlight::Middlewares::HeaderMarker, RailsSpotlight::Middlewares::RequestCompleted, app.config
      if defined? ActionDispatch::Executor
        app.middleware.insert_after ActionDispatch::Executor, ::RailsSpotlight::Middlewares::RequestCompleted, app.config
      else
        app.middleware.use ::RailsSpotlight::Middlewares::RequestCompleted
      end
    end

    def app
      Rails.application
    end
  end
end
