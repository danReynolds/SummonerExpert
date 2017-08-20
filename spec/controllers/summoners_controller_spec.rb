require 'rails_helper'
require 'spec_contexts.rb'

describe SummonersController, type: :controller do
  include_context 'spec setup'
  include_context 'determinate speech'

  before :each do
    allow(controller).to receive(:summoner_params).and_return(summoner_params)
  end

  describe 'POST description' do
    let(:action) { :description }
    let(:external_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][action]
    end
    let(:summoner_params) do
      { name: 'Wingilote', region: 'na1', queue: 'RANKED_SOLO_5x5' }
    end

    before :each do
      allow(RiotApi::RiotApi).to receive(:fetch_response).and_return(
        external_response
      )
      allow(RiotApi::RiotApi).to receive(:get_summoner_id).and_return(1)
    end

    context 'when valid' do
      it 'should return the summoner information' do
        post action, params: params
        expect(speech).to eq 'Wingilote is ranked Gold V in Solo Queue. The summoner currently has a 50.16% win rate and is not on a hot streak.'
      end

      it 'should vary the information by queue' do
        summoner_params[:queue] = 'RANKED_FLEX_SR'
        post action, params: params
        expect(speech).to eq 'Wingilote is ranked Bronze I in Flex Queue. The summoner currently has a 60.78% win rate and is not on a hot streak.'
      end
    end
  end
end
