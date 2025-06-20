module RailsSpotlight
  module NotificationExtension
    def instrument(name, payload = {}, &block)
      if payload.is_a?(Hash) && !payload.key?(:original_callsite)
        callsite = ::RailsSpotlight::Utils.dev_callsite(caller_locations)
        if callsite && callsite[:filename].present?
          payload[:original_callsite] = callsite
        end
      end

      super(name, payload, &block)
    end
  end
end
