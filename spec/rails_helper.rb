# frozen_string_literal: true

require 'pry'
ENV['RAILS_ENV'] ||= 'test'

begin
  require 'active_record'
rescue LoadError
end

require 'rails/all'
require 'rspec/rails'
require 'action_cable/testing/rspec'
require 'pathname'
ActionCable.server.config.cable = {'adapter' => 'async'}

module Rails
  class << self
    def root
      Pathname.new(File.expand_path(__FILE__).split('/')[0..-3].join('/'))
    end

    def env
      'test'.inquiry
    end

    def logger
      Logger.new(Rails.root.join('log', 'test.log')) # Logger.new(STDOUT)
    end
  end
end

module FakeApp
  class Application < Rails::Application
  end
end

Rails.application.configure do
  config.cache_classes = false
  config.action_view.cache_template_loading = true
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = false
  config.action_controller.allow_forgery_protection = false
  config.active_support.deprecation = :stderr
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []
  config.log_level = :debug
end

# Configure the database connection
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: File.expand_path('fixtures/test.sqlite3', __dir__)
)

User = Class.new(ActiveRecord::Base)

# Check if the database exists, and create it if it doesn't
if ActiveRecord::Base.connection.data_source_exists?('users')
  User.delete_all
else
  ActiveRecord::Schema.define(version: 2024_01_01_000001) do
    create_table(:users) do |t|
      t.string :name
      t.string :email
      t.timestamps
    end
  end
end

User.delete_all
10.times do |i|
  User.create(name: "User #{i}", email: "user#{i}@example.com")
end


Rails.application.routes.draw do
  get '/', to: ->(_env) { [200, {'Content-Type' => 'text/html'}, ['Test']] }
  get '/some_other_path', to: ->(_env) { [200, {'Content-Type' => 'text/html'}, ['just test path']] }
end

require 'rails_spotlight'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
end
