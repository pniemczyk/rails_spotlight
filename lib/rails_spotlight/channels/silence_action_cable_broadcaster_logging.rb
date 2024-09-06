# frozen_string_literal: true

module RailsSpotlight
  module Channels
    module SilenceActionCableBroadcasterLogging
      refine ActionCable::Server::Broadcasting::Broadcaster do
        def broadcast(message)
          if broadcasting == RailsSpotlight::Channels::SpotlightChannel::SPOTLIGHT_CHANNEL
            original_logger = server.logger
            begin
              # Replace the logger with a no-op logger to silence the log
              server.logger = ActiveSupport::Logger.new(nil)
              super(message)
            ensure
              # Restore the original logger after broadcasting
              server.logger = original_logger
            end
          else
            super(message)
          end
        end
      end
    end
  end
end
