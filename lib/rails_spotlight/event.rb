# frozen_string_literal: true

require 'active_support'
require 'active_support/json'
require 'active_support/core_ext'

module RailsSpotlight
  # Subclass of ActiveSupport Event that is JSON encodable
  #
  class Event < ActiveSupport::Notifications::Event
    NOT_JSON_ENCODABLE = 'Not JSON Encodable'

    attr_reader :duration

    def initialize(name, start, ending, transaction_id, payload)
      super(name, start, ending, transaction_id, json_encodable(payload))
      @duration = 1000.0 * (ending - start)
    end

    def self.events_for_exception(exception_wrapper)
      if defined?(ActionDispatch::ExceptionWrapper)
        exception = exception_wrapper.exception
        trace = exception_wrapper.application_trace
        trace = exception_wrapper.framework_trace if trace.empty?
      else
        exception = exception_wrapper
        trace = exception.backtrace
      end
      trace.unshift "#{exception.class} (#{exception.message})"
      trace.map do |call|
        Event.new('process_action.action_controller.exception', 0, 0, nil, call: call)
      end
    end

    private

    def json_encodable(payload)
      return {} unless payload.is_a?(Hash)

      transform_hash(payload, deep: true) do |hash, key, value|
        value_class = value.class.to_s
        if value_class == 'ActionDispatch::Http::Headers'
          value = value.to_h.select { |k, _| k.upcase == k }
        elsif value_class == 'SystemStackError' || not_encodable?(value)
          value = NOT_JSON_ENCODABLE
        end

        begin
          value.to_json(methods: [:duration])
          new_value = value
        rescue StandardError, SystemStackError
          new_value = NOT_JSON_ENCODABLE
        end
        hash[key] = new_value
      end.with_indifferent_access
    end

    def not_encodable?(value)
      ::RailsSpotlight.config.not_encodable_event_values.any? do |module_name, class_names|
        next unless defined?(module_name.constantize)

        class_names.any? { |class_name| value.is_a?(class_name.constantize) }
      rescue # rubocop:disable Lint/RescueException, Lint/RedundantCopDisableDirective, Style/RescueStandardError
        false
      end
    end

    def transform_hash(original, options = {}, &block)
      options[:safe_descent] ||= {}.compare_by_identity

      # Check if the hash has already been transformed to prevent infinite recursion.
      return options[:safe_descent][original] if options[:safe_descent].key?(original)

      # Create a new hash to store the transformed values.
      new_hash = {}
      # Store the new hash in safe_descent using the original's object_id to mark it as processed.
      options[:safe_descent][original] = new_hash

      # Iterate over each key-value pair in the original hash.
      original.each do |key, value|
        # If deep transformation is required and the value is a hash,
        # recursively transform it, unless it's already been transformed.
        if options[:deep] && Hash === value # rubocop:disable Style/CaseEquality
          value = options[:safe_descent].fetch(value) do
            transform_hash(value, options, &block)
          end
        end
        # Apply the transformation block to the current key-value pair.
        block.call(new_hash, key, value)
      end

      # Return the transformed hash.
      new_hash
    end
  end
end
