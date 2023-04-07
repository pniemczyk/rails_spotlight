require_relative 'handlers/base_action_handler'
require_relative 'handlers/file_action_handler'
require_relative 'handlers/sql_action_handler'
require_relative 'handlers/verify_action_handler'
require_relative 'handlers/not_found_action_handler'

module RailsSpotlight
  module Middlewares
    class RequestHandler
      def initialize(app)
        @app = app
      end

      def call(env)
        path_info = env['PATH_INFO']
        action, content_type = path_info.match(%r{/__rails_spotlight/(.+)\.(\w+)$}).try(:captures)
        return handle(Rack::Request.new(env), action, content_type.try(:to_sym)) if action

        app.call(env)
      end

      private

      attr_reader :app

      def handle(request, action, content_type = :json)
        args = [SecureRandom.uuid, request, content_type]
        case action
        when 'file' then Handlers::FileActionHandler.new(*args).call
        when 'sql' then Handlers::SqlActionHandler.new(*args).call
        when 'verify' then Handlers::VerifyActionHandler.new(*args).call
        else
          Handlers::NotFoundActionHandler.new(*args).call
        end
      end
    end
  end
end
