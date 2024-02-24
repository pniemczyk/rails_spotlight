# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class SqlActionHandler < BaseActionHandler
        def execute
          validate_project!
          return transaction unless ActiveSupport.const_defined?('ExecutionContext')

          ActiveSupport::ExecutionContext.set(rails_spotlight: request_id) do
            transaction
          end
        end

        private

        def validate_project!
          return if required_projects.blank?
          return if required_projects.include?(::RailsSpotlight.config.project_name)

          raise UnprocessableEntity, "Check your connection settings the current query is not allowed to be executed on the #{::RailsSpotlight.config.project_name} project"
        end

        def transaction
          ActiveRecord::Base.transaction do
            begin # rubocop:disable Style/RedundantBegin
              ActiveSupport::Notifications.subscribed(method(:logger), 'sql.active_record', monotonic: true) do
                run
              end
            rescue => e # rubocop:disable Style/RescueStandardError
              self.error = e
            ensure
              raise ActiveRecord::Rollback unless force_execution?
            end
          end
        end

        def run # rubocop:disable Metrics/AbcSize
          RailsSpotlight.config.logger && RailsSpotlight.config.logger.info("Executing query: #{query}") # rubocop:disable Style/SafeNavigation
          return self.result = ActiveRecord::Base.connection.exec_query(query) if connection_options.blank? || !ActiveRecord::Base.respond_to?(:connects_to)

          connections = ActiveRecord::Base.connects_to(**connection_options)

          adapter = connections.find { |c| c.role == use['role'] && c.shard.to_s == use['shard'] }
          raise UnprocessableEntity, "Connection not found for role: `#{use["role"]}` and shard: `#{use["shard"]}`" if adapter.blank?

          self.result = adapter.connection.exec_query(query)
        end

        attr_accessor :result, :error

        def json_response_body
          {
            query: query,
            result: result,
            logs: logs,
            error: error.present? ? error.inspect : nil,
            query_mode: force_execution? ? 'force' : 'default',
            project: ::RailsSpotlight.config.project_name
          }
        end

        def logger(_, started, finished, unique_id, payload)
          logs << { time: started, end: finished, unique_id: unique_id }.merge(
            payload.as_json(except: %i[connection method name filename line])
          )
        end

        def logs
          @logs ||= []
        end

        def query
          @query ||= json_request_body.fetch('query')
        end

        def raw_options
          @raw_options ||= json_request_body.fetch('options', {}) || {}
        end

        def required_projects
          @required_projects ||= raw_options.fetch('projects', [])
        end

        def use
          @use ||= { 'shard' => 'default', 'role' => 'reading' }.merge(raw_options.fetch('use', {}))
        end

        def connection_options
          @connection_options ||= raw_options
                                  .symbolize_keys
                                  .slice(:database, :shards)
                                  .reject { |_, v| v.nil? || (!v.is_a?(TrueClass) && !v.is_a?(FalseClass) && v.empty?) } # TODO: Check for each rails version
        end

        def force_execution?
          @force_execution ||= json_request_body['mode'] == 'force'
        end
      end
    end
  end
end
