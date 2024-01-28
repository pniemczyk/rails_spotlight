# frozen_string_literal: true

module RailsSpotlight
  module Channels
    autoload(:LiveConsoleChannel, 'rails_spotlight/channels/live_console_channel') if defined?(ActionCable)
    autoload(:RequestCompletedChannel, 'rails_spotlight/channels/request_completed_channel') if defined?(ActionCable)
  end
end
