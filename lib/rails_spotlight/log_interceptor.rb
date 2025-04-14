# frozen_string_literal: true

require_relative 'channels'

module RailsSpotlight
  module LogInterceptor
    SEVERITY_MAP = { 0 => 'debug', 1 => 'info', 2 => 'warn', 3 => 'error', 4 => 'fatal', 5 => 'unknown' }.freeze

    def debug(message = nil, *args, &)
      _rails_spotlight_log(:debug, message, nil, &)
      super
    end

    def info(message = nil, *args, &)
      _rails_spotlight_log(:info, message, nil, &)
      super
    end

    def warn(message = nil, *args, &)
      _rails_spotlight_log(:warn, message, nil, &)
      super
    end

    def error(message = nil, *args, &)
      _rails_spotlight_log(:error, message, nil, &)
      super
    end

    def fatal(message = nil, *args, &)
      _rails_spotlight_log(:fatal, message, nil, &)
      super
    end

    def unknown(message = nil, *args, &)
      _rails_spotlight_log(:unknown, message, nil, &)
      super
    end

    private

    def _skip_cable_logging?(message)
      return false unless ::RailsSpotlight.config.use_cable?
      return false unless ActionCable.server.config&.cable&.dig(:adapter).present?

      message.include?(::RailsSpotlight::Channels::SPOTLIGHT_CHANNEL)
    end

    def _rails_spotlight_log(severity, message, progname = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return if message.nil? && !block_given?

      severity ||= :unknown
      level = SEVERITY_MAP[severity.to_s]

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end

      return unless message.is_a?(String)

      callsite = Utils.dev_callsite(caller.drop(1))
      name = progname.is_a?(String) || progname.is_a?(Symbol) ? progname : nil

      AppRequest.current.events << Event.new('rsl.notification.log', 0, 0, 0, (callsite || {}).merge(message:, level: severity, progname: name)) if AppRequest.current
      return if _skip_cable_logging?(message)

      ::RailsSpotlight::Channels::SpotlightChannel.broadcast_log(message, level, callsite, name)
    rescue StandardError => e
      RailsSpotlight.config.logger.fatal("#{e.message}\n #{e.backtrace&.join("\n ")}")
    end
  end
end
