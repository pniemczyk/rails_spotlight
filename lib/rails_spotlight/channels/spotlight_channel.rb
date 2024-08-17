# frozen_string_literal: true

require_relative 'handlers'
# require_relative 'silence_action_cable_broadcaster_logging'

module RailsSpotlight
  module Channels
    class SpotlightChannel < ActionCable::Channel::Base
      def self.broadcast(attrs = {})
        broadcasting = ::RailsSpotlight::Channels::SPOTLIGHT_CHANNEL
        message = {
          type: attrs[:type],
          code: attrs[:code] || 'ok',
          project: ::RailsSpotlight.config.project_name,
          version: ::RailsSpotlight::VERSION,
          payload: attrs[:payload] || {}
        }
        coder = ::ActiveSupport::JSON
        encoded = coder ? coder.encode(message) : message
        ActionCable.server.pubsub.broadcast(broadcasting, encoded)
        # We do not use the following code because it is triggering logs and can cause an infinite loop
        # ActionCable.server.broadcast(
        #   ::RailsSpotlight::Channels::SPOTLIGHT_CHANNEL,
        #   {
        #     type: attrs[:type],
        #     code: attrs[:code] || 'ok',
        #     project: ::RailsSpotlight.config.project_name,
        #     version: ::RailsSpotlight::VERSION,
        #     payload: attrs[:payload] || {}
        #   }
        # )
      rescue StandardError => e
        RailsSpotlight.config.logger.fatal("#{e.message}\n #{e.backtrace.join("\n ")}")
      end

      def subscribed
        stream_from ::RailsSpotlight::Channels::SPOTLIGHT_CHANNEL
        publish({ message: "Your #{project} project is now connected to the spotlight channel.", code: :connected, type: :info })
      end

      def unsubscribed
        # Any cleanup needed when channel is unsubscribed
      end

      def receive(data)
        return publish({ message: 'Unknown type of request', code: :unknown_type, type: :error }) unless Handlers::TYPES.include?(data['type'])

        result = Handlers.handle(data)
        publish({ payload: result[:payload], code: result[:code] || :ok, type: data['type'] }) if result[:payload]
      rescue ::RailsSpotlight::Channels::Handlers::ResponseError => e
        publish({ message: e.message, code: e.code, type: :error })
      end

      private

      def publish(data)
        connection.transmit identifier: @identifier, message: data.merge(project: project, version: version)
        # we do not use transmit because it is triggering logs and can cause an infinite loop
        # transmit(data.merge(project: project, version: version))
      end

      def project
        ::RailsSpotlight.config.project_name
      end

      def version
        ::RailsSpotlight::VERSION
      end
    end
  end
end
