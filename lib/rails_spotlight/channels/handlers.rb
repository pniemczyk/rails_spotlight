# frozen_string_literal: true

require_relative 'handlers/live_console_handler'
require_relative 'handlers/logs_handler'

module RailsSpotlight
  module Channels
    module Handlers
      ResponseError = Class.new(StandardError) do
        def initialize(message, code: :error)
          @code = code
          super(message)
        end

        attr_reader :code
      end
      TYPES = [LiveConsoleHandler::TYPE, LogsHandler::TYPE].freeze

      def self.handle(data)
        case data['type']
        when LiveConsoleHandler::TYPE then LiveConsoleHandler.new(data).call
        # when LogsHandler::TYPE then LogsHandler.new(data).call
        else
          nil
        end
      end
    end
  end
end
