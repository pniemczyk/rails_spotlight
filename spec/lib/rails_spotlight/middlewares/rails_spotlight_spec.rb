# frozen_string_literal: true

require 'rails_helper'

Rails.application.config.middleware.use RailsSpotlight::Middlewares::RequestHandler

RSpec.describe RailsSpotlight::Middlewares, type: :request do
  describe 'RequestHandler' do
    context 'when requesting a file action' do
      it 'returns forbidden when file manager is disabled' do
        expect(::RailsSpotlight.config).to receive(:file_manager_enabled).and_return(false)
        body = { file: 'spec/fixtures/test.txt', mode: 'read' }.to_json
        post '/__rails_spotlight/file.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to_not be_successful
        expect(response).to have_http_status(:forbidden)
        json_body = JSON.parse(response.body)
        expect(json_body['code']).to eq('disabled_file_manager_settings')
        expect(json_body['status']).to eq(403)
      end

      it 'as read mode returns response correctly' do
        expect(::RailsSpotlight.config).to receive(:file_manager_enabled).and_return(true)
        body = { file: 'spec/fixtures/test.txt', mode: 'read' }.to_json
        post '/__rails_spotlight/file.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['source']).to eq("Test content\n")
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['changed']).to eq(false)
        expect(json_response['in_project']).to be_truthy
        expect(json_response['relative_path']).to eq('spec/fixtures/test.txt')
        expect(json_response['root_path']).to eq(Rails.root.to_s)
      end

      it 'as write mode returns response correctly' do
        expect(::RailsSpotlight.config).to receive(:file_manager_enabled).and_return(true)
        expect(::RailsSpotlight.config).to receive(:block_editing_files).and_return(false)
        body = { file: 'spec/fixtures/test.txt', mode: 'write', content: 'change the text' }.to_json
        expect(File).to receive(:write).with(Rails.root.join('spec/fixtures/test.txt').to_s, 'change the text')
        post '/__rails_spotlight/file.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['source']).to eq("Test content\n")
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['changed']).to eq(true)
        expect(json_response['new_content']).to eq("change the text")
        expect(json_response['in_project']).to be_truthy
        expect(json_response['relative_path']).to eq('spec/fixtures/test.txt')
        expect(json_response['root_path']).to eq(Rails.root.to_s)
      end

      it 'as write mode returns return unprocessed when editing file is blocked' do
        expect(::RailsSpotlight.config).to receive(:file_manager_enabled).and_return(true)
        expect(::RailsSpotlight.config).to receive(:block_editing_files).and_return(true)
        body = { file: 'spec/fixtures/test.txt', mode: 'write', content: 'change the text' }.to_json
        post '/__rails_spotlight/file.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to_not be_successful
      end

      it 'as write mode returns return unprocessed when editing file outside project is blocked is blocked' do
        expect(::RailsSpotlight.config).to receive(:file_manager_enabled).and_return(true)
        expect(::RailsSpotlight.config).to receive(:block_editing_files).and_return(false)
        expect(::RailsSpotlight.config).to receive(:block_editing_files_outside_of_the_project)
        expect(File).to receive(:exist?).at_least(:once) do |args|
          args == '/User/spec/fixtures/test.txt'
        end
        body = { file: '/User/spec/fixtures/test.txt', mode: 'write', content: 'change the text' }.to_json
        post '/__rails_spotlight/file.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to_not be_successful
      end
    end

    context 'when requesting a directory index action' do
      it 'returns forbidden when file manager is disabled' do
        expect(::RailsSpotlight.config).to receive(:file_manager_enabled).and_return(false)
        body = {
          ignore: RailsSpotlight::Configuration::DEFAULT_DIRECTORY_INDEX_IGNORE + %w[.gitignore .bundle /tmp /extensions],
          omnit_gitignore: false,
          show_empty_directories: false
        }.to_json
        post '/__rails_spotlight/directory_index.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to_not be_successful
        expect(response).to have_http_status(:forbidden)
        json_body = JSON.parse(response.body)
        expect(json_body['code']).to eq('disabled_file_manager_settings')
        expect(json_body['status']).to eq(403)
      end

      it 'returns response correctly' do
        expect(::RailsSpotlight.config).to receive(:file_manager_enabled).and_return(true)
        body = {
          ignore: RailsSpotlight::Configuration::DEFAULT_DIRECTORY_INDEX_IGNORE + %w[.gitignore .bundle /tmp /extensions],
          omnit_gitignore: false,
          show_empty_directories: false
        }.to_json
        post '/__rails_spotlight/directory_index.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['root_path']).to eq(Rails.root.to_s)
        root_dir = json_response['result']
        expect(root_dir['path']).to eq('.')
        expect(root_dir['name']).to eq('rails_spotlight')
        expect(root_dir['dir']).to be_truthy
        expect(root_dir['children'].count).to be > 0
        readme_file = root_dir['children'].find { |child| child['name'] == 'README.md' }
        expect(readme_file).to_not be_nil
        expect(readme_file['dir']).to be_falsey
        expect(readme_file['children']).to be_empty
      end
    end

    context 'when requesting a verify action' do
      it 'returns response correctly' do
        body = { test: 'ok' }.to_json
        post '/__rails_spotlight/verify.json?check=yes', params: body, headers: { 'CONTENT_TYPE' => 'application/json', 'HTTP_X_RAILS_SPOTLIGHT' => '1.0.0' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['current_gem_version']).to eq(RailsSpotlight::VERSION)
        expect(json_response['version']).to eq("1.0.0")
        expect(json_response['request_method']).to eq("POST")
        expect(json_response['content_type']).to eq("application/json")
        expect(json_response['body']).to eq("{\"test\":\"ok\"}")
        expect(json_response['params']).to eq({"check"=>"yes"})
        expect(json_response['action_cable_path']).to be_nil
        expect(json_response['current_gem_version']).to eq(RailsSpotlight::VERSION)
        expect(json_response['version']).to eq('1.0.0')
        expect(json_response['for_projects']).to eq([])
      end
    end

    context 'when requesting a sql action' do
      let!(:user_data) { { name: 'test_man', email: 'just@simple.com' } }
      before { User.create!(user_data) unless User.find_by(email: user_data[:email]) }

      it 'returns forbidden when sql manager is disabled' do
        expect(::RailsSpotlight.config).to receive(:sql_console_enabled?).and_return(false)
        body = { query: 'select * from users', mode: :soft }.to_json
        post '/__rails_spotlight/sql.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to_not be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['code']).to eq('disabled_sql_console_settings')
        expect(json_response['status']).to eq(403)
      end

      it 'as soft mode returns response correctly' do
        expect(::RailsSpotlight.config).to receive(:sql_console_enabled?).and_return(true)
        body = { query: 'select * from users', mode: :soft }.to_json
        post '/__rails_spotlight/sql.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['query']).to eq("select * from users")
        expect(json_response['query_mode']).to eq("default")
        expect(json_response['error']).to be_nil
        expect(json_response['logs']).to_not be_nil
        expect(json_response['result'].count).to eq(User.count)
      end

      it 'as force mode returns response correctly' do
        expect(::RailsSpotlight.config).to receive(:sql_console_enabled?).and_return(true)
        body = { query: "delete from users where email=\"#{user_data[:email]}\"", mode: :force }.to_json
        expect {
          post '/__rails_spotlight/sql.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        }.to change { User.count }.by(-1)
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['query']).to eq("delete from users where email=\"#{user_data[:email]}\"")
        expect(json_response['query_mode']).to eq("force")
        expect(json_response['error']).to be_nil
        expect(json_response['logs']).to_not be_nil
        expect(json_response['result'].count).to eq(0)
        expect(User.find_by(email: user_data[:email])).to be_nil
      end

      it 'as soft mode with destructive query returns response correctly' do
        expect(::RailsSpotlight.config).to receive(:sql_console_enabled?).and_return(true)
        body = { query: "delete from users where email=\"#{user_data[:email]}\"", mode: :default }.to_json
        expect {
          post '/__rails_spotlight/sql.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        }.to change { User.count }.by(0)
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['query']).to eq("delete from users where email=\"#{user_data[:email]}\"")
        expect(json_response['query_mode']).to eq("default")
        expect(json_response['error']).to be_nil
        expect(json_response['logs']).to_not be_nil
        expect(json_response['result'].count).to eq(0)
        expect(User.find_by(email: user_data[:email])).to_not be_nil
      end
    end

    context 'when requesting an unknown action' do
      it 'handles not found action' do
        get '/__rails_spotlight/unknown.json'
        expect(response).to have_http_status(:not_found)
        # Additional assertions for not found behavior
      end
    end

    context 'when requesting a path not handled by middleware' do
      it 'processes request normally' do
        get '/some_other_path'
        expect(response).to be_successful
        expect(response.body).to eq('just test path')
      end
    end

    context 'when requesting a meta action' do
      before do
        allow(RailsSpotlight.config).to receive(:storage_path).and_return(Rails.root.join('spec/fixtures/storage'))
      end

      it 'returns response correctly' do
        get '/__rails_spotlight/meta.json?id=0a9aadaf-9bb4-4ae0-8146-ab4c99d1110e', headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['events']).to_not be_nil
      end
    end
  end
end
