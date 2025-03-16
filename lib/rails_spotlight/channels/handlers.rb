# frozen_string_literal: true

require_relative 'handlers/console_handler'
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
      TYPES = [ConsoleHandler::TYPE, LogsHandler::TYPE].freeze

      def self.handle(data)
        case data['type']
        when ConsoleHandler::TYPE then ConsoleHandler.new(data).call
        when LogsHandler::TYPE then LogsHandler.new(data).call
        end
      end
    end
  end
end
