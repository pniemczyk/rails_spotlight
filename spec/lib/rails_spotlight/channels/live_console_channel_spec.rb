require 'rails_helper'

RSpec.describe RailsSpotlight::Channels::LiveConsoleChannel, type: :channel do
  include ActionCable::TestHelper

  before do
    subscribe
  end

  it 'successfully subscribes' do
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from('rails_spotlight_live_console_channel')
  end

  describe '#receive' do
    context 'when the command is valid' do
      let(:data) { { 'command' => '2 + 2', 'inspect_types' => true, 'project' => 'FakeApp' } }

      it 'executes the command and publishes the output' do
        perform :receive, data

        output = transmissions.last
        expect(output).to include('result')
        expect(output['project']).to eq('FakeApp')
        result = output['result']
        expect(result.keys).to match_array(%w[inspect raw type types console])
        expect(result['inspect']).to eq('4')
        expect(result['raw']).to eq(4)
        expect(result['type']).to eq('Integer')
        expect(result['types']['root']).to eq("Integer")
        expect(result['types']['items']).to eq({})
      end
    end

    context 'when there is a project mismatch' do
      let(:data) { { 'command' => '2 + 2', 'inspect_types' => true, 'project' => 'DifferentProject' } }

      it 'sends an error message about project mismatch' do
        perform :receive, data

        output = transmissions.last

        expect(output).to include(:error)
        expect(output['error']).to match(/Project mismatch/)
        expect(output['project']).to eq('FakeApp')
      end
    end
  end
end
