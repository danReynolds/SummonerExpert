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

  shared_examples 'load summoner' do
    it 'should load the summoner' do
      expect(controller).to receive(:load_summoner).and_call_original
      post action, params
    end
  end

  describe '#load_summoner' do
    context 'without valid region' do
      before :each do
        allow(controller).to receive(:summoner_params).and_return(
          region: 'fake region',
          summoner: 'mordequess'
        )
      end

      it 'should state the region is invalid' do
        expect(controller).to receive(:render).with(
          json: { speech: 'region is not included in the list' }
        )
        expect(controller.send(:load_summoner)).to eq false
      end
    end

    context 'without valid id' do
      before :each do
        allow(controller).to receive(:summoner_params).and_return(
          region: 'na',
          summoner: 'mordequess'
        )
        allow(RiotApi::RiotApi).to receive(:get_summoner_id).and_return(nil)
      end

      it 'should state the region is invalid' do
        expect(controller).to receive(:render).with(
          json: { speech: 'id could not be found for the given summoner name.' }
        )
        expect(controller.send(:load_summoner)).to eq false
      end
    end

    context 'when valid' do
      before :each do
        allow(controller).to receive(:summoner_params).and_return(
          region: 'na',
          summoner: 'mordequess'
        )
        allow(RiotApi::RiotApi).to receive(:get_summoner_id).and_return(1)
      end

      it 'should assign the region and the summoner' do
        expect(controller.send(:load_summoner)).to_not eq false
        expect(assigns(:region).valid?).to eq true
        expect(assigns(:summoner).valid?).to eq true
      end
    end
  end

  describe 'POST champion' do
    let(:action) { :champion }
    let(:external_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][action]
    end

    before :each do
      allow(RiotApi::RiotApi).to receive(:get_summoner_champions).and_return(
        external_response
      )
      allow(RiotApi::RiotApi).to receive(:get_summoner_id).and_return(1)
    end

    context 'with summoner champion data' do
      it "should show data for the summoner's performance with that champion" do
        post action, params
        expect(speech).to eq "wingilote has a 10/8/6 KDA and 44.0% win rate on Nocturne overall in 25 games. The summoner gets first blood 0% of the time and takes an average of 1 tower, 70 cs and 14667 gold per game."
      end
    end

    context 'without summoner champion data' do
      before :each do
        allow(RiotApi::RiotApi).to receive(:get_summoner_champions).and_return(
          []
        )
      end

      it 'should indicatae that the summoner does not play that champion' do
        post action, params
        expect(speech).to eq controller.send(:does_not_play_response)[:speech]
      end
    end
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
      allow(RiotApi::RiotApi).to receive(:get_summoner_id).and_return(1)
    end

    it_should_behave_like 'load summoner'

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
