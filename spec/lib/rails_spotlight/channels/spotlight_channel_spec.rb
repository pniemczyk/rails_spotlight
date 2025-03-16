require 'rails_helper'
require 'rails_spotlight/channels/handlers'
require 'rails_spotlight/channels/handlers/console_handler'
require 'rails_spotlight/channels/handlers/logs_handler'
require 'rails_spotlight/channels/spotlight_channel'


RSpec.describe RailsSpotlight::Channels::SpotlightChannel, type: :channel do
  include ActionCable::TestHelper

  before do
    subscribe
  end

  it 'successfully subscribes' do
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(::RailsSpotlight::Channels::SPOTLIGHT_CHANNEL)
  end

  describe '#receive' do
    context 'when the type is console and command is valid' do
      let(:data) { { 'type' => 'console', 'command' => '2 + 2', 'inspect_types' => true, 'project' => 'FakeApp' } }

      it 'executes the command and publishes the output' do
        expect(::RailsSpotlight.config).to receive(:cable_logs_enabled?).and_return(true)
        perform :receive, data

        output = transmissions.last

        expect(output).to include('payload')
        payload = output['payload']
        expect(output['project']).to eq('FakeApp')
        expect(output['type']).to eq('console')
        expect(output['code'].to_s).to eq('ok')
        expect(output['version']).to eq(::RailsSpotlight::VERSION)
        result = payload['result']
        expect(result.keys).to match_array(%w[inspect raw type types console status])
        expect(result['inspect']).to eq('4')
        expect(result['raw']).to eq(4)
        expect(result['type']).to eq('Integer')
        expect(result['types']['root']).to eq("Integer")
        expect(result['types']['items']).to eq({})
      end
    end

    context 'when type is console there is a project mismatch' do
      let(:data) { { 'type' => 'console', 'command' => '2 + 2', 'inspect_types' => true, 'project' => 'DifferentProject' } }

      it 'sends an error message about project mismatch' do
        expect(::RailsSpotlight.config).to receive(:cable_logs_enabled?).and_return(true)
        perform :receive, data

        output = transmissions.last

        expect(output['project']).to eq('FakeApp')
        expect(output['type'].to_s).to eq('error')
        expect(output['code'].to_s).to eq('project_mismatch')
        expect(output['version']).to eq(::RailsSpotlight::VERSION)
        expect(output['message']).to match(/Project mismatch/)
      end
    end
  end
end
