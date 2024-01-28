# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module SkipRequestPaths
      PATHS_TO_SKIP = %w[/__better_errors /__rails_spotlight /__meta_request].freeze

      private

      def skip?(path)
        skip_paths.any? { |skip_path| path.start_with?(skip_path) } || asset?(path)
      end

      def default_skip_paths
        PATHS_TO_SKIP
      end

      def additional_skip_paths
        []
      end

      def skip_paths
        additional_skip_paths + default_skip_paths + ::RailsSpotlight.config.middleware_skipped_paths
      end

      def asset?(path)
        app_config.respond_to?(:assets) && path.start_with?(assets_prefix)
      end

      def assets_prefix
        "/#{app_config.assets.prefix[%r{\A/?(.*?)/?\z}, 1]}/"
      end
    end
  end
end
