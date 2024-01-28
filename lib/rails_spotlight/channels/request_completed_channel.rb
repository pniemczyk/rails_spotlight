# frozen_string_literal: true

module RailsSpotlight
  module Channels
    class RequestCompletedChannel < ActionCable::Channel::Base
      def subscribed
        stream_from 'rails_spotlight_request_completed_channel'
      end

      def unsubscribed
        # Any cleanup needed when channel is unsubscribed
      end
    end
  end
end
