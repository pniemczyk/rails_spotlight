module RailsSpotlight
  module Middlewares
    module Handlers
      class NotFoundActionHandler < BaseActionHandler
        def execute
          raise NotFound, 'Not found'
        end
      end
    end
  end
end
