# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class BaseActionHandler
        IncorrectResponseContentType = Class.new(StandardError)
        NotFound = Class.new(StandardError)
        UnprocessableEntity = Class.new(StandardError)

        def initialize(request_id, request, content_type)
          @request_id = request_id
          @request = request
          @content_type = content_type
        end

        attr_reader :request_id, :request, :content_type

        def call
          execute
          response
        rescue NotFound => e
          not_found_response(e.message)
        rescue UnprocessableEntity => e
          unprocessed_response(e.message)
        rescue => e # rubocop:disable Style/RescueStandardError
          internal_server_error_response(e.message)
        end

        protected

        attr_writer :status, :headers

        def headers
          @headers ||= {}
        end

        def status
          @status ||= 200
        end

        def execute
          raise 'Not implemented yet'
        end

        def json_response_body
          raise IncorrectResponseContentType, content_type
        end

        def text_response_body
          raise IncorrectResponseContentType, content_type
        end

        def json_request_body
          @json_request_body ||= JSON.parse(request.body.read)
        rescue JSON::ParserError
          raise 'Invalid JSON'
        end

        def internal_server_error_response(message)
          response(500, message_to_body(message))
        end

        def unprocessed_response(message)
          response(422, message_to_body(message))
        end

        def not_found_response(message)
          response(404, message_to_body(message))
        end

        def message_to_body(message)
          content_type == :json ? { message: message } : message
        end

        def response_headers(headers = {})
          {
            'Content-Type' => content_type == :json ? 'application/json; charset=utf-8' : 'text/plain; charset=utf-8',
            'X-Rails-Spotlight' => '1.0.0',
            'X-Request-Id' => request_id
          }.merge(headers)
        end

        def response(overridden_status = nil, overridden_body = nil)
          body = if overridden_body.present?
                   content_type == :json ? overridden_body.to_json : overridden_body
                 else
                   content_type == :json ? json_response_body.to_json : text_response_body
                 end
          [overridden_status.present? ? overridden_status : status, response_headers(headers), [body]]
        end
      end
    end
  end
end
