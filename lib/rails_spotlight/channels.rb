# frozen_string_literal: true

module RailsSpotlight
  module Channels
    SPOTLIGHT_CHANNEL = 'RailsSpotlight::Channels::SpotlightChannel'.freeze # rubocop:disable Style/RedundantFreeze
    autoload(:SpotlightChannel, 'rails_spotlight/channels/spotlight_channel') if defined?(ActionCable)
  end
end
