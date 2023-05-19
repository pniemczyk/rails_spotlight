module RailsSpotlight
  module Support
    class Project
      include Singleton

      def name
        @name ||= ENV['RAILS_SPOTLIGHT_PROJECT'] || if app_class.respond_to?(:module_parent_name)
                                                      app_class.module_parent_name
                                                    else
                                                      app_class.parent_name
                                                    end
      end

      def app_class
        @app_class ||= Rails.application.class
      end
    end
  end
end
