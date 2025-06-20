# frozen_string_literal: true

module RailsSpotlight
  module NotificationExtension
    def instrument(name, payload = {}, &)
      if payload.is_a?(Hash) && !payload.key?(:original_callsite)
        callsite = ::RailsSpotlight::Utils.dev_callsite(caller_locations)
        payload[:original_callsite] = callsite if callsite && callsite[:filename].present?
      end

      super
    end
  end
end
