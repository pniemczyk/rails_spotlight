# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    module Handlers
      class NotFoundActionHandler < BaseActionHandler
        def execute
          raise NotFound.new('Not found', code: :action_not_found)
        end
      end
    end
  end
end
