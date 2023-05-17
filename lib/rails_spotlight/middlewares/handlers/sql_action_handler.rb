# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class SqlActionHandler < BaseActionHandler
        def execute
          if ActiveSupport.const_defined?('ExecutionContext')
            ActiveSupport::Notifications.subscribed(method(:logger), 'sql.active_record', monotonic: true) do
              ActiveSupport::ExecutionContext.set(rails_spotlight: request_id) do
                transaction
              end
            end
          else
            ActiveSupport::Notifications.subscribed(method(:logger), 'sql.active_record') do
              transaction
            end
          end
        end

        private

        def transaction
          ActiveRecord::Base.transaction do
            begin
              self.result = ActiveRecord::Base.connection.exec_query(query)
            rescue => e
              self.error = e
            ensure
              raise ActiveRecord::Rollback unless force_execution?
            end
          end
        end

        attr_accessor :result
        attr_accessor :error

        def json_response_body
          { result: result, logs: logs, error: error.inspect, query_mode: force_execution? ? 'force' : 'default' }
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

        def force_execution?
          @force_execution ||= json_request_body['mode'] == 'force'
        end
      end
    end
  end
end
