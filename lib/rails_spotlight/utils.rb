# frozen_string_literal: true

module RailsSpotlight
  module Utils
    module_function

    def dev_callsite(caller_locations)
      loc = caller_locations.detect { |c| c.path.start_with? RailsSpotlight.config.rails_root }
      return nil unless loc

      {
        filename: sub_source_path(loc.path),
        line: loc.lineno,
        method: loc.label
      }
    rescue # rubocop:disable Style/RescueStandardError, Lint/SuppressedException
    end

    def sub_source_path(path)
      rails_root = RailsSpotlight.config.rails_root
      source_path = RailsSpotlight.config.source_path
      return path if rails_root == source_path

      path.sub(rails_root, source_path)
    end
  end
end
