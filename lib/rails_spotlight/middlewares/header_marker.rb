# frozen_string_literal: true

require 'rack/contrib/response_headers'
require_relative 'concerns/skip_request_paths'

module RailsSpotlight
  module Middlewares
    class HeaderMarker
      include ::RailsSpotlight::Middlewares::SkipRequestPaths

      def initialize(app, app_config)
        @app = app
        @app_config = app_config
      end

      def call(env)
        request_path = env['PATH_INFO']
        return app.call(env) if skip?(request_path)

        middleware = Rack::ResponseHeaders.new(app) do |headers|
          headers['X-Rails-Spotlight-Version'] = RailsSpotlight::VERSION
        end
        middleware.call(env)
      end

      private

      attr_reader :app, :app_config

      def default_skip_paths = %w[/__better_errors /__meta_request /rails]
    end
  end
end
