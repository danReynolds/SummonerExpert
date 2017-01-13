require 'rails_helper'

describe SummonersController, type: :controller do
  let(:resources) do
    JSON.parse(File.read('api.json')).with_indifferent_access[:resources]
  end
  let(:params) do
    res = resources.detect do |res|
      res[:name] == "summoners/#{action}"
    end
    JSON.parse(res[:body][:text])
  end

  def speech
    JSON.parse(response.body).with_indifferent_access[:speech]
  end

  describe 'POST show' do
    let(:action) { :show }
    let(:external_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][action]
    end

    before :each do
      allow(RiotApi::RiotApi).to receive(:get_summoner_stats).and_return(
        external_response[:summoner_stats]
      )
      allow(RiotApi::RiotApi).to receive(:get_summoner_champions).and_return(
        external_response[:summoner_champions]
      )
    end

    context 'on hot streak' do
      let(:response_text) do
        "mordequess is on a hot streak. The player is ranked Silver V with 23LP in Solo Queue and is ranked Bronze I with 44LP in Flex Queue. Playing mordequess's most common champions, the summoner has a a 51.61% win rate on Jhin in 31 games, a 54.17% win rate on Caitlyn in 24 games, and a 36.36% win rate on Garen in 11 games."
      end

      before :each do
        external_response[:summoner_stats].first[:isHotStreak] = true
      end

      it 'should return the stats, champions, and hot streak for the player' do
        post action, params
        expect(speech).to eq response_text
      end
    end

    context 'not on hot streak' do
      let(:response_text) do
        "mordequess is ranked Silver V with 23LP in Solo Queue and is ranked Bronze I with 44LP in Flex Queue. Playing mordequess's most common champions, the summoner has a a 51.61% win rate on Jhin in 31 games, a 54.17% win rate on Caitlyn in 24 games, and a 36.36% win rate on Garen in 11 games."
      end

      it 'should return the stats and champions for the player' do
        post action, params
        expect(speech).to eq response_text
      end
    end
  end
end
