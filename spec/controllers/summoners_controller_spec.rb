require 'rails_helper'
require 'spec_contexts.rb'

describe SummonersController, type: :controller do
  include_context 'spec setup'
  include_context 'determinate speech'

  before :each do
    allow(controller).to receive(:summoner_params).and_return(summoner_params)
  end

  describe 'POST show' do
    let(:action) { :show }
    let(:external_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][action]
    end
    let(:summoner_params) do
      { name: 'Wingilote', region: 'na1', queue: 'RANKED_SOLO_5x5' }
    end

    before :each do
      Cache.set_summoner_queues(summoner_params[:name], summoner_params[:region], nil)
      Cache.set_summoner_id(summoner_params[:name], summoner_params[:region], nil)
      allow(RiotApi::RiotApi).to receive(:fetch_response).and_return(
        external_response
      )
      allow(RiotApi::RiotApi).to receive(:get_summoner_id).and_return(1)
      allow(RiotApi::RiotApi).to receive(:get_summoner_queues).and_call_original
    end

    context 'when cached' do
      it 'should not make an API request' do
        post action, params: params
        post action, params: params

        expect(RiotApi::RiotApi).to have_received(:get_summoner_id).once
        expect(RiotApi::RiotApi).to have_received(:get_summoner_queues).once
      end
    end

    context 'with no queue information' do
      before :each do
        allow(RiotApi::RiotApi).to receive(:fetch_response).and_return({})
      end

      it 'should indicate that the summoner does not play in that queue' do
        post action, params: params
        expect(speech).to eq 'Wingilote is not currently an active player in Solo Queue.'
      end
    end

    it 'should return the summoner information' do
      post action, params: params
      expect(speech).to eq 'Wingilote is ranked Gold V with 84 LP in Solo Queue. The summoner currently has a 50.16% win rate and is not on a hot streak.'
    end

    it 'should vary the information by queue' do
      summoner_params[:queue] = 'RANKED_FLEX_SR'
      post action, params: params
      expect(speech).to eq 'Wingilote is ranked Bronze I with 28 LP in Flex Queue. The summoner currently has a 60.78% win rate and is not on a hot streak.'
    end
  end
end
