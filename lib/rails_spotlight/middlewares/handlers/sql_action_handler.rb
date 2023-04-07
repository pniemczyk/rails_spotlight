module RailsSpotlight
  module Middlewares
    module Handlers
      class SqlActionHandler < BaseActionHandler
        def execute
          ActiveSupport::Notifications.subscribed(method(:logger), 'sql.active_record', monotonic: true) do
            ActiveSupport::ExecutionContext.set(rails_spotlight: request_id) do
              self.result = ActiveRecord::Base.connection.exec_query(query)
            end
          end
        end

        private

        attr_accessor :result

        def json_response_body
          { result: result, logs: logs }
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
      end
    end
  end
end
