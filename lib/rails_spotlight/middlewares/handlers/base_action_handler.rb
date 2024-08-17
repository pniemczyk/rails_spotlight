# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class BaseActionHandler
        IncorrectResponseContentType = Class.new(StandardError)
        NotFound = Class.new(StandardError)
        UnprocessableEntity = Class.new(StandardError)
        Forbidden = Class.new(StandardError)

        def initialize(request_id, request, content_type)
          @request_id = request_id
          @request = request
          @content_type = content_type
        end

        attr_reader :request_id, :request, :content_type

        def call
          validate_project! unless skip_project_validation?
          execute
          response
        rescue NotFound => e
          not_found_response(e.message)
        rescue UnprocessableEntity => e
          unprocessed_response(e.message)
        rescue Forbidden => e
          forbidden_response(e.message)
        rescue => e # rubocop:disable Style/RescueStandardError
          internal_server_error_response(e.message)
        end

        protected

        attr_writer :status, :headers

        def skip_project_validation?
          false
        end

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

        def body_fetch(*args)
          json_request_body.fetch(*args)
        end

        def internal_server_error_response(message)
          response(500, message_to_body(message))
        end

        def unprocessed_response(message)
          response(422, message_to_body(message))
        end

        def forbidden_response(message)
          response(403, message_to_body(message))
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
            'X-Rails-Spotlight' => ::RailsSpotlight::VERSION,
            'X-Rails-Spotlight-Project' => ::RailsSpotlight.config.project_name,
            'X-Request-Id' => request_id
          }.merge(headers)
        end

        def response(overridden_status = nil, overridden_body = nil)
          body = if overridden_body.present?
                   content_type == :json ? overridden_body.to_json : overridden_body
                 else
                   content_type == :json ? json_response_body.merge({ project: ::RailsSpotlight.config.project_name }).to_json : text_response_body
                 end
          [overridden_status.present? ? overridden_status : status, response_headers(headers), [body]]
        end

        def request_spotlight_version
          @request_spotlight_version ||= request.get_header('HTTP_X_RAILS_SPOTLIGHT')
        end

        def request_for_projects
          @request_for_projects ||= (request.get_header('HTTP_X_FOR_PROJECTS') || '').split(',').map(&:strip)
        end

        def validate_project!
          return if request_for_projects.blank?
          return if request_for_projects.include?(::RailsSpotlight.config.project_name)

          raise Forbidden, "Check your settings the current request is not allowed to be executed on the #{::RailsSpotlight.config.project_name} project"
        end
      end
    end
  end
end
