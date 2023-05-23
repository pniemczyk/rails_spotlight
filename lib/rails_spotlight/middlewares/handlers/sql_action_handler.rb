# frozen_string_literal: true

require_relative '../../support/project'

module RailsSpotlight
  module Middlewares
    module Handlers
      class SqlActionHandler < BaseActionHandler
        def execute
          return transaction unless ActiveSupport.const_defined?('ExecutionContext')

          transaction
        end

        private

        def transaction
          ActiveRecord::Base.transaction do
            begin
              ActiveSupport::Notifications.subscribed(method(:logger), 'sql.active_record', monotonic: true) do
                run
              end
            rescue => e
              self.error = e
            ensure
              raise ActiveRecord::Rollback unless force_execution?
            end
          end
        end

        def run
          return self.result = ActiveRecord::Base.connection.exec_query(query) if connection_options.blank? || !ActiveRecord::Base.respond_to?(:connected_to)

          ActiveRecord::Base.connected_to(connection_options) do
            self.result = ActiveRecord::Base.connection.exec_query(query)
          end
        end

        attr_accessor :result
        attr_accessor :error

        def json_response_body
          {
            query: query,
            result: result,
            logs: logs,
            error: error.present? ? error.inspect : nil,
            query_mode: force_execution? ? 'force' : 'default',
            project: ::RailsSpotlight::Support::Project.instance.name
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

        def connection_options
          @connection_options ||= json_request_body
                                    .fetch('connection_options', {})
                                    .symbolize_keys
                                    .slice(:database, :role, :shard, :prevent_writes) # TODO: Check for each rails version
        end

        def force_execution?
          @force_execution ||= json_request_body['mode'] == 'force'
        end
      end
    end
  end
end
