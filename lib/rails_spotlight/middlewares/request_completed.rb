# frozen_string_literal: true

require_relative 'concerns/skip_request_paths'
require_relative '../channels/spotlight_channel'

module RailsSpotlight
  module Middlewares
    class RequestCompleted
      include ::RailsSpotlight::Middlewares::SkipRequestPaths

      def initialize(app, app_config)
        @app = app
        @app_config = app_config
      end

      def call(env)
        return app.call(env) unless ::RailsSpotlight.config.request_completed_broadcast_enabled?

        if skip?(env['PATH_INFO']) || (env['HTTP_CONNECTION'] == 'Upgrade' && env['HTTP_UPGRADE'] == 'websocket')
          app.call(env)
        else
          status, headers, body = app.call(env)
          publish_event(status, headers, env)
          [status, headers, body]
        end
      rescue => e # rubocop:disable Style/RescueStandardError
        ::RailsSpotlight.config.logger.error "Error in RailsSpotlight::Middlewares::RequestCompletedHandler instrumentation: #{e.message}"
        app.call(env)
      end

      private

      attr_reader :app, :app_config

      def rails_spotlight_request_id
        Thread.current[:rails_spotlight_request_id]&.id
      end

      def publish_event(status, _headers, env)
        return if status < 100
        return unless rails_spotlight_request_id

        request = ActionDispatch::Request.new(env)

        host, url = host_and_url(env)
        RailsSpotlight::Channels::SpotlightChannel.broadcast(
          {
            type: 'request_completed',
            payload: {
              id: rails_spotlight_request_id,
              http_method: env['REQUEST_METHOD'],
              host:,
              url:,
              format: request.format.symbol,
              controller: request.path_parameters[:controller],
              action: request.path_parameters[:action]
            }
          }
        )
      end

      def host_and_url(env)
        scheme = env['rack.url_scheme']
        host = env['HTTP_HOST']
        path = env['PATH_INFO']
        query_string = env['QUERY_STRING']

        host_url = "#{scheme}://#{host}"
        full_url = "#{host_url}#{path}"
        full_url += "?#{query_string}" unless query_string.empty?
        [host_url, full_url]
      end
    end
  end
end
