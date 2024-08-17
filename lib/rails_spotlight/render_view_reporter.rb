# frozen_string_literal: true

module RailsSpotlight
  class RenderViewReporter
    def self.report_rendered_view_locals(view, locals: nil, params: nil, show_devise: false, skip_vars: [], metadata: {})
      ActiveSupport::Notifications.instrument(
        'render_view.locals',
        params: params,
        locals: serialize_as_json(locals),
        instance_variables: dev_instance_variables(view, skip_vars: skip_vars, show_devise: show_devise),
        metadata: metadata
      )
    end

    def self.serialize_as_json(value)
      value.respond_to?(:as_json) ? value.as_json : nil
    rescue => e # rubocop:disable Style/RescueStandardError
      {
        __serialization_error: e.message,
        __source: value.inspect
      }
    end

    def self.dev_instance_variables(source, skip_vars: [], show_devise: false)
      source.instance_variables.map do |name|
        next if skip_vars.include?(name)
        next if RailsSpotlight.config.skip_rendered_ivars.include?(name)
        next if !show_devise && name == :@devise_parameter_sanitizer

        [name[1..], source.instance_variable_get(name)]
      end.compact.to_h
    end
  end
end
