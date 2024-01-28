# frozen_string_literal: true

require 'rails_helper'

Rails.application.config.middleware.use RailsSpotlight::Middlewares::RequestHandler

RSpec.describe RailsSpotlight::Middlewares, type: :request do
  describe 'RequestHandler' do
    context 'when requesting a file action' do
      it 'as read mode returns response correctly' do
        body = { file: 'spec/fixtures/test.txt', mode: 'read' }.to_json
        post '/__rails_spotlight/file.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['source']).to eq("Test content\n")
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['changed']).to eq(false)
      end

      it 'as write mode returns response correctly' do
        body = { file: 'spec/fixtures/test.txt', mode: 'write', content: 'change the text' }.to_json
        expect(File).to receive(:write).with(Rails.root.join('spec/fixtures/test.txt').to_s, 'change the text')
        post '/__rails_spotlight/file.json', params: body, headers: { 'CONTENT_TYPE' => 'application/json' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['source']).to eq("Test content\n")
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['changed']).to eq(true)
        expect(json_response['new_content']).to eq("change the text")
      end
    end

    context 'when requesting a verify action' do
      it 'returns response correctly' do
        body = { test: 'ok' }.to_json
        post '/__rails_spotlight/verify.json?check=yes', params: body, headers: { 'CONTENT_TYPE' => 'application/json', 'HTTP_X_RAILS_SPOTLIGHT' => '1.0.0' }
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['project']).to eq("FakeApp")
        expect(json_response['current_gem_version']).to eq("0.2.0")
        expect(json_response['version']).to eq("1.0.0")
        expect(json_response['request_method']).to eq("POST")
        expect(json_response['content_type']).to eq("application/json")
        expect(json_response['body']).to eq("{\"test\":\"ok\"}")
        expect(json_response['params']).to eq({"check"=>"yes"})
        expect(json_response['action_cable_path']).to be_nil
      end
    end

    context 'when requesting a sql action' do
      let!(:user_data) { { name: 'test_man', email: 'just@simple.com' } }
      before { User.create!(user_data) unless User.find_by(email: user_data[:email]) }
      it 'as soft mode returns response correctly' do
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
