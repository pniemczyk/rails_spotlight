# frozen_string_literal: true

require 'active_support'
require 'active_support/json'
require 'active_support/core_ext'

module RailsSpotlight
  # Subclass of ActiveSupport Event that is JSON encodable
  class Event < ActiveSupport::Notifications::Event # rubocop:disable Metrics/ClassLength
    NOT_JSON_ENCODABLE = 'Not JSON Encodable'
    NON_SERIALIZABLE_CLASSES = [Proc, Binding, Method, UnboundMethod, Thread, IO, Class, Module].freeze

    attr_reader :duration, :seen_not_encodable

    def initialize(name, start, ending, transaction_id, payload)
      @seen_not_encodable = Set.new
      raw_payload = json_encodable(payload)
      raw_payload.merge!(raw_payload[:original_callsite]) if raw_payload[:original_callsite].present? && raw_payload[:filename].blank?
      super(name, start, ending, transaction_id, raw_payload)
      @duration = 1000.0 * (ending - start)
    rescue # rubocop:disable Lint/RedundantCopDisableDirective, Style/RescueStandardError
      @duration = 0
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
        Event.new('process_action.action_controller.exception', 0, 0, nil, call:)
      end
    end

    private

    def json_encodable(payload)
      return {} unless payload.is_a?(Hash)

      transform_hash(payload, deep: true) do |hash, key, value|
        hash[key] = encode_json_safe_value(value)
      end.with_indifferent_access
    rescue # rubocop:disable Style/RescueStandardError
      {}
    end

    def not_json_encodable_and_seen(value)
      seen_not_encodable.add(value.__id__)
      NOT_JSON_ENCODABLE
    end

    def encode_json_safe_value(value) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return not_json_encodable_and_seen(value) if not_encodable?(value)
      return NOT_JSON_ENCODABLE unless value.respond_to?(:to_json)

      case value
      when ActionDispatch::Http::Headers
        value = value.to_h.select { |k, _| k.upcase == k }
      when Array
        value = value.map do |v|
          encode_json_safe_value(v)
        rescue StandardError
          NOT_JSON_ENCODABLE
        end
      when Hash
        value = transform_hash(value, deep: true) { |h, k, v| h[k] = encode_json_safe_value(v) }
      when ActiveRecord::Relation::QueryAttribute
        map_relation_query_attribute(value)
      # when ActionController::Parameters
      #   value = value.to_unsafe_h rescue value.to_h
      else
        value = map_relation_query_attribute(value) if defined?(ActiveRecord::Relation::QueryAttribute) && value.is_a?(ActiveRecord::Relation::QueryAttribute)
      end

      begin
        value.to_json(methods: [:duration])
        value
      rescue # rubocop:disable Style/RescueStandardError
        NOT_JSON_ENCODABLE
      end
    end

    def transform_hash(original, options = {}, &block)
      options[:safe_descent] ||= {}.compare_by_identity

      return cached_transformation(original, options) if already_transformed?(original, options)

      new_hash = {}
      cache_transformation(original, new_hash, options)

      original.each do |key, value|
        value = deep_transform_value(value, options, &block) if options[:deep]
        block.call(new_hash, key, value)
      end

      new_hash
    end

    def already_transformed?(object, options)
      options[:safe_descent].key?(object)
    end

    def cached_transformation(object, options)
      options[:safe_descent][object]
    end

    def cache_transformation(original, transformed, options)
      options[:safe_descent][original] = transformed
    end

    def deep_transform_value(value, options, &)
      return value unless value.is_a?(Hash)
      return cached_transformation(value, options) if already_transformed?(value, options)

      transform_hash(value, options, &)
    end

    # ActiveRecord::Relation::QueryAttribute implementation changed in Rails 7.1 it getting binds need to be manually added
    def map_relation_query_attribute(attr)
      {
        name: attr.name,
        value: attr.value,
        value_before_type_cast: attr.value_before_type_cast,
        value_for_database: attr.value_for_database
        # resign from type and original_attribute for now
        # type: attr.type,
        # original_attribute: attr.original_attribute or attr.original_value_for_database,
      }
    end

    def not_encodable?(value) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return true if value_too_large?(value)
      return true if NON_SERIALIZABLE_CLASSES.any? { |klass| value.is_a?(klass) }

      ::RailsSpotlight.config.not_encodable_event_values.any? do |module_name, class_names|
        next true unless safe_constantize(module_name)

        class_names.any? do |class_name|
          klass = safe_constantize(class_name)
          klass && value.is_a?(klass)
        end
      rescue # rubocop:disable Style/RescueStandardError
        true
      end
    end

    def value_too_large?(value)
      return false unless defined?(ObjectSpace)
      return false unless RailsSpotlight.config.maximum_event_value_size

      (ObjectSpace.memsize_of(value) > RailsSpotlight.config.maximum_event_value_size)
    rescue # rubocop:disable Style/RescueStandardError
      false
    end

    def safe_constantize(name)
      name.constantize
    rescue NameError
      nil
    end
  end
end
