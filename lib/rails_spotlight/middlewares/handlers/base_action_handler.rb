# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class BaseActionHandler
        BaseError = Class.new(StandardError) do
          attr_reader :code, :status

          def initialize(message = nil, code: nil)
            super(message)
            @code = code
            @status = case self.class.name.demodulize.underscore
                      when 'unsupported_media_type' then 415
                      when 'not_found' then 404
                      when 'unprocessable_entity' then 422
                      when 'forbidden' then 403
                      else 500
                      end
          end
        end
        UnsupportedMediaType = Class.new(BaseError)
        NotFound = Class.new(BaseError)
        UnprocessableEntity = Class.new(BaseError)
        Forbidden = Class.new(BaseError)

        def initialize(request_id, request, content_type)
          @request_id = request_id
          @request = request
          @content_type = content_type
        end

        attr_reader :request_id, :request, :content_type

        def call
          validate_data_access! if data_access_token
          validate_project! unless skip_project_validation?
          execute
          response
        rescue BaseError => e
          error_response(e)
        rescue => e # rubocop:disable Style/RescueStandardError
          error_response(BaseError.new(e.message))
        end

        protected

        attr_writer :status, :headers

        def skip_project_validation? = false
        def headers = @headers ||= {}
        def status = @status ||= 200

        def execute
          raise 'Not implemented yet'
        end

        def json_response_body
          raise UnsupportedMediaType.new(content_type, code: :unsupported_media_type_json)
        end

        def text_response_body
          raise UnsupportedMediaType.new(content_type, code: :unsupported_media_type_text)
        end

        def json_request_body
          @json_request_body ||= JSON.parse(request.body.read)
        rescue JSON::ParserError
          raise 'Invalid JSON'
        end

        def body_fetch(*args) = json_request_body.fetch(*args)
        def error_response(error) = response(error.status || 500, message_to_body(error.message, code: error.code, status: error.status || 500))
        def message_to_body(message, code: :none, status: 500) = content_type == :json ? { message:, code:, status: } : message

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

        def request_spotlight_version = @request_spotlight_version ||= request.get_header('HTTP_X_RAILS_SPOTLIGHT')
        def request_for_projects = @request_for_projects ||= (request.get_header('HTTP_X_FOR_PROJECTS') || '').split(',').map(&:strip)

        def validate_project!
          return if request_for_projects.blank?
          return if request_for_projects.include?(::RailsSpotlight.config.project_name)

          raise Forbidden.new(
            "Check your settings the current request is not allowed to be executed on the #{::RailsSpotlight.config.project_name} project",
            code: :project_mismatch
          )
        end

        def data_access_token = ::RailsSpotlight.config.data_access_token

        def validate_data_access!
          return if request.get_header('HTTP_X_DATA_ACCESS_TOKEN') == data_access_token

          raise Forbidden.new('Invalid data access token', code: :invalid_data_access_token)
        end
      end
    end
  end
end
