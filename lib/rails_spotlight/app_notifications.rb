# frozen_string_literal: true

module RailsSpotlight
  class AppNotifications
    # these are the specific keys in the cache payload that we display in the
    # panel view
    CACHE_KEY_COLUMNS = %i[key hit options type].freeze

    # define this here so we can pass it in to all of our cache subscribe calls
    CACHE_BLOCK = proc { |*args|
      name, start, ending, transaction_id, payload = args

      # from http://edgeguides.rubyonrails.org/active_support_instrumentation.html#cache-fetch-hit-active-support
      #
      # :super_operation  :fetch is added when a read is used with #fetch
      #
      # so if :super_operation is present, we'll use it for the type. otherwise
      # strip (say) 'cache_delete.active_support' down to 'delete'
      payload[:type] = payload.delete(:super_operation) || name.sub(/cache_(.*?)\..*$/, '\1')

      # anything that isn't in CACHE_KEY_COLUMNS gets shoved into :options
      # instead
      payload[:options] = {}
      payload.each_key do |k|
        payload[:options][k] = payload.delete(k) unless k.in? CACHE_KEY_COLUMNS
      end

      callsite = payload[:original_callsite] || ::RailsSpotlight::Utils.dev_callsite(caller_locations)
      payload.merge!(callsite) if callsite

      Event.new(name, start, ending, transaction_id, payload)
    }

    VIEW_LOCALS_BLOCK = proc { |*args|
      name, start, ending, transaction_id, payload = args
      Event.new(name, start, ending, transaction_id, payload)
    }

    # sql processing block - used for sql.active_record and sql.sequel

    # HACK: we hardcode the event name to 'sql.active_record' so that the ui will
    # display sequel events without modification. otherwise the ui would need to
    # be modified to support a sequel tab (or to change the display name on the
    # active_record tab when necessary - which maybe makes more sense?)
    SQL_EVENT_NAME = 'sql.active_record'

    SQL_BLOCK = proc { |*args|
      _name, start, ending, transaction_id, payload = args
      callsite = payload[:original_callsite] || ::RailsSpotlight::Utils.dev_callsite(caller_locations)
      payload.merge!(callsite) if callsite

      Event.new(SQL_EVENT_NAME, start, ending, transaction_id, payload)
    }

    VIEW_BLOCK = proc { |*args|
      name, start, ending, transaction_id, payload = args
      payload[:identifier] = ::RailsSpotlight::Utils.sub_source_path(payload[:identifier])

      Event.new(name, start, ending, transaction_id, payload)
    }

    CONTROLLER_BLOCK = proc { |*args|
      name, start, ending, transaction_id, payload = args
      payload[:identifier] = ::RailsSpotlight::Utils.sub_source_path(payload[:identifier])
      # Payload of redirect_to
      # { status: 302, location: "http://localhost:3000/posts/new", request: <ActionDispatch::Request:0x00007ff1cb9bd7b8> }
      # Payload of process_action
      # { controller: "PostsController", action: "index", params: {"action" => "index", "controller" => "posts"}, format: :html, method: "GET", path: "/posts",
      #   headers: #<ActionDispatch::Http::Headers:0x0055a67a519b88>, request: #<ActionDispatch::Request:0x00007ff1cb9bd7b8>, response: #<ActionDispatch::Response:0x00007f8521841ec8>,
      #   status: 200, view_runtime: 46.848, db_runtime: 0.157
      # }
      # Payload of send_stream.action_controller
      # { filename: "subscribers.csv", type: "text/csv", disposition: "attachment" }

      Event.new(name, start, ending, transaction_id, payload)
    }


    # Subscribe to all relevant events
    def self.subscribe
      # Skip RailsSpotlight subscriptions during migrations
      return if migrating?

      new
        .subscribe('rsl.notification.log') # We do not publish events to this channel for now
        .subscribe('sql.active_record', &SQL_BLOCK)
        .subscribe('sql.sequel', &SQL_BLOCK)
        .subscribe('render_partial.action_view', &VIEW_BLOCK)
        .subscribe('render_template.action_view', &VIEW_BLOCK)
        .subscribe('process_action.action_controller.exception')
        .subscribe('process_action.action_controller') do |*args|
          name, start, ending, transaction_id, payload = args
          payload[:status] = '500' if payload[:exception]
          Event.new(name, start, ending, transaction_id, payload)
        end
        .subscribe('cache_read.active_support', &CACHE_BLOCK)
        .subscribe('cache_generate.active_support', &CACHE_BLOCK)
        .subscribe('cache_fetch_hit.active_support', &CACHE_BLOCK)
        .subscribe('cache_write.active_support', &CACHE_BLOCK)
        .subscribe('cache_delete.active_support', &CACHE_BLOCK)
        .subscribe('cache_exist?.active_support', &CACHE_BLOCK)
        .subscribe('render_view.locals', &VIEW_LOCALS_BLOCK)
        # .subscribe('start_processing.action_controller', &CONTROLLER_BLOCK)
        # .subscribe('redirect_to.action_controller', &CONTROLLER_BLOCK)
        # .subscribe('send_file.action_controller', &CONTROLLER_BLOCK)

      # TODO: Consider adding these events
      # start_processing.action_controller: Triggered when a controller action starts processing a request.
      # send_file.action_controller: Triggered when a file is sent as a response.
      # redirect_to.action_controller: Triggered when a redirect response is sent.
      # halted_callback.action_controller: Triggered when a filter or callback halts the request.
      # render_collection.action_view: This event is triggered when a collection is rendered using a partial.
      #                                It includes details about the collection being rendered,
      #                                such as the collection name and the partial being used to render each item.
    end

    def self.migrating?
      defined?(Rake) && Rake.application.top_level_tasks.any? do |task|
        task.start_with?('db:')
      end
    end

    def subscribe(event_name)
      # Look for details about instrumentation => https://guides.rubyonrails.org/active_support_instrumentation.html#railties
      ActiveSupport::Notifications.subscribe(event_name) do |*args|
        next if ::RailsSpotlight.config.disable_active_support_subscriptions.include?(event_name)

        event = block_given? ? yield(*args) : Event.new(*args)
        AppRequest.current.events << event if AppRequest.current
      end
      self
    end
  end
end
