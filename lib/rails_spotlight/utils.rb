# frozen_string_literal: true

module RailsSpotlight
  module Utils
    module_function

    def dev_callsite(caller)
      app_line = caller.detect { |c| c.start_with? RailsSpotlight.config.rails_root }
      return nil unless app_line

      _, filename, _, line, _, method = app_line.split(/^(.*?)(:(\d+))(:in `(.*)')?$/)

      {
        filename: sub_source_path(filename),
        line: line.to_i,
        method: method
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
