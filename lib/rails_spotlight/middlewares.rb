# frozen_string_literal: true

module RailsSpotlight
  module Middlewares
    autoload :RequestHandler,     'rails_spotlight/middlewares/request_handler'
    autoload :RequestCompleted,   'rails_spotlight/middlewares/request_completed'
    autoload :HeaderMarker,       'rails_spotlight/middlewares/header_marker'
    autoload :MainRequestHandler, 'rails_spotlight/middlewares/main_request_handler'
  end
end
