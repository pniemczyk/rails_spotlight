# frozen_string_literal: true

require_relative 'channels'

module RailsSpotlight
  module LogInterceptor
    SEVERITY = %w[debug info warn error fatal unknown].freeze
    SEVERITY_MAP = { 0 => 'debug', 1 => 'info', 2 => 'warn', 3 => 'error', 4 => 'fatal', 5 => 'unknown' }.freeze

    def add(severity, message = nil, progname = nil) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      severity ||= 5
      return true if @logdev.nil? || severity < level

      progname = @progname if progname.nil?

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end
      return true if _skip_logging?(message)

      _rails_spotlight_log(SEVERITY_MAP[severity], message, progname, :broadcast)
      super(severity, message, progname) if defined?(super)
      true
    end


    def debug(message = nil, *args, &block)
      _rails_spotlight_log(:debug, message, nil, :event, &block)
      super
    end

    def info(message = nil, *args, &block)
      _rails_spotlight_log(:info, message, nil, :event, &block)
      super
    end

    def warn(message = nil, *args, &block)
      _rails_spotlight_log(:warn, message, nil, :event, &block)
      super
    end

    def error(message = nil, *args, &block)
      _rails_spotlight_log(:error, message, nil, :event, &block)
      super
    end

    def fatal(message = nil, *args, &block)
      _rails_spotlight_log(:fatal, message, nil, :event, &block)
      super
    end

    def unknown(message = nil, *args, &block)
      _rails_spotlight_log(:unknown, message, nil, :event, &block)
      super
    end

    private

    def _skip_logging?(message)
      return false unless ::RailsSpotlight.config.use_action_cable?
      return false unless message.is_a?(String)

      message.include?(::RailsSpotlight::Channels::SPOTLIGHT_CHANNEL)
    end

    def _rails_spotlight_log(level, message, progname = nil, output = :event)
      callsite = Utils.dev_callsite(caller.drop(1))
      name = progname.is_a?(String) || progname.is_a?(Symbol) ? progname : nil
      message = yield if output == :event && message.nil? && block_given?
      output == :event ? _push_event(level, message, name, callsite) : _broadcast_log(message, level, callsite, name)
    rescue StandardError => e
      RailsSpotlight.config.logger.fatal("#{e.message}\n #{e.backtrace.join("\n ")}")
    end

    def _push_event(level, message, progname = nil, callsite = {})
      name = progname.is_a?(String) || progname.is_a?(Symbol) ? progname : nil
      AppRequest.current.events << Event.new('rsl.notification.log', 0, 0, 0, (callsite || {}).merge(message: message, level: level, progname: name)) if AppRequest.current
    rescue StandardError => e
      RailsSpotlight.config.logger.fatal("#{e.message}\n #{e.backtrace.join("\n ")}")
    end

    def _broadcast_log(message, level, callsite = {}, name = nil)
      return unless ::RailsSpotlight.config.use_action_cable?
      return if message.blank?

      id = AppRequest.current ? AppRequest.current.id : nil # rubocop:disable Style/SafeNavigation
      payload = (callsite || {}).merge(msg: message, src: ENV['RS_SRC'] || ::RailsSpotlight.config.default_rs_src, l: level, dt: Time.now.to_f, id: id, pg: name)
      ::RailsSpotlight::Channels::SpotlightChannel.broadcast(type: 'logs', payload: payload)
    rescue StandardError => e
      RailsSpotlight.config.logger.fatal("#{e.message}\n #{e.backtrace.join("\n ")}")
    end
  end
end
