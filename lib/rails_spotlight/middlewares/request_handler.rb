module RailsSpotlight
  module Middlewares
    class RequestHandler
      def initialize(app)
        @app = app
      end

      def call(env)
        action = env['PATH_INFO'][%r{/__rails_spotlight/(.+)\.json$}, 1]
        return handle(request: Rack::Request.new(env), action:) if action

        app.call(env)
      end

      private

      attr_reader :app

      def handle(request:, action:)
        request_id = SecureRandom.uuid
        case action
        when 'file' then file_response(request, request_id)
        when 'sql' then sql_response(request, request_id)
        when 'verify' then verify_response(request, request_id)
        else
          response(status: 404, content_type: :text, body: 'Not found')
        end
      end

      def sql_response(request, request_id)
        query = extract_json(request).fetch('query')
        logs = []
        logger = ->(_, started, finished, unique_id, payload) {
          logs << {
            time: started, end: finished, unique_id:,
          }.merge(payload.as_json(except: %i[connection method name filename line]))
        }
        result = nil
        ActiveSupport::Notifications.subscribed(logger, "sql.active_record", monotonic: true) do
          ActiveSupport::ExecutionContext.set(rails_spotlight: request_id) do
            result = ActiveRecord::Base.connection.exec_query(query)
          end
        end
        response(
          request_id:,
          body: {
            result:,
            logs:
          }.to_json
        )
      end

      def file_response(request, request_id)
        json = extract_json(request)
        file_path = Rails.root.join(json.fetch('file'))
        raise 'File not found' unless File.exist?(file_path)

        mode = json.fetch('mode') { 'read' }
        File.write(file_path, json.fetch('content')) if mode == 'write'
        response(content_type: :text, request_id:, body: File.read(file_path))
      rescue => ex
        unprocessed_response(ex.message, request_id:)
      end

      def verify_response(response, request_id)
        response(
          request_id:,
          body: {
            params: response.params,
            body: response.body.read,
            content_type: response.content_type,
            request_method: response.request_method,
            version: response.get_header('HTTP_X_RAILS_SPOTLIGHT')
          }.to_json
        )
      end

      def extract_json(request)
        body = request.body.read
        JSON.parse(body)
      rescue JSON::ParserError
        raise 'Invalid JSON'
      end

      def unprocessed_response(message, request_id)
        response(status: 422, content_type: :text, body: message, request_id:)
      end

      def response(status: nil, headers: {}, content_type: :json, body:, request_id:)
        response_content_type = content_type == :json ? 'application/json; charset=utf-8' : 'text/plain; charset=utf-8'
        response_headers = {
          'Content-Type' => response_content_type,
          'X-Rails-Spotlight' => '1.0.0',
          'X-Request-Id' => request_id
        }.merge(headers)
        [status || 200, response_headers, [body]]
      end
    end
  end
end
