# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe DummyController, type: :request do # rubocop:disable Metrics/BlockLength
  context 'rails_spotlight' do
    it 'serve a file source' do
      post '/__rails_spotlight/file.json', params: { file: 'config/application.rb', mode: :read }.to_json

      expect(response).to be_successful
      expect(response.body).to include('# Require the gems listed in Gemfile, including any gems')
    end

    it 'write content to the file' do
      content = 'TEST'
      file = 'README.md'
      File.write(Rails.root.join(file), 'OLD')
      expect(File.read(Rails.root.join(file))).to_not eq content

      post '/__rails_spotlight/file.json', params: { file: file, mode: :write, content: content }.to_json

      expect(response).to be_successful
      expect(response.body).to eq({ source: content }.to_json)
      expect(File.read(Rails.root.join(file))).to eq content
    end

    it 'serve a verify info' do
      get '/__rails_spotlight/verify.json'
      expect(response).to be_successful
    end

    it 'serve a sql result' do
      post '/__rails_spotlight/sql.json', params: { query: 'select sqlite_version();' }.to_json
      expect(response).to be_successful
      expect(JSON.parse(response.body).keys).to eq(%w[result logs])
    end
  end

  context 'meta_request specs' do
    before do
      # clean up meta_request files
      FileUtils.rm_rf(Rails.root.join('tmp', 'data', 'meta_request'))
      get '/'
      @request_id = response.headers['X-Request-Id']
    end

    let(:request_id) { @request_id }

    it 'should have a request_id header' do
      expect(request_id).to be_present
    end

    it 'should have a meta_request version header' do
      expect(response.headers['X-Meta-Request-Version']).to eq(MetaRequest::VERSION)
    end

    it 'should create a request file' do
      expect(Dir[Rails.root.join('tmp/data/meta_request/*.json')].size).to eq(1)
    end

    it 'should serve a meta_request' do
      get "/__meta_request/#{request_id}.json"
      expect(response).to be_successful
    end
  end
end
