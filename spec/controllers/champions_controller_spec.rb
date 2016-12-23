require 'rails_helper'

describe ChampionsController, type: :controller do
  let(:resources) do
    JSON.parse(File.read('api.json')).with_indifferent_access[:resources]
  end
  let(:params) do
    res = resources.detect do |res|
      res[:name] == "champions/#{action}"
    end
    JSON.parse(res[:body][:text])
  end

  def speech
    JSON.parse(response.body).with_indifferent_access[:speech]
  end

  describe 'POST title' do
    let(:action) { :title }

    it 'should return the champions title' do
      post action, params
      expect(speech).to eq "Sona's title is Maven of the Strings"
    end
  end

  describe 'POST build' do
    let(:action) { :build }

    context 'when valid role specified' do
      context 'when no role' do
        before :each do
          champion_params = params['result']['parameters']
          champion_params['lane'] = nil
        end

        context 'champion has only one role' do
          it 'should provide a build for a champion using their only role' do
            post action, params
            expect(speech).to eq "The highest win rate build for Bard Support is Boots of Mobility, Sightstone, Frost Queen's Claim, Redemption, Knight's Vow, Locket of the Iron Solari"
          end
        end

        context 'when champion has more than one role' do
          it 'should ask for the role' do
            champion = RiotApi::RiotApi.get_champion('Bard')
            champion[:champion_gg] << champion[:champion_gg].first
            allow(RiotApi::RiotApi).to receive(:get_champion).and_return(champion)
            post action, params

            expect(speech).to eq controller.send(
              :ask_for_role_response,
              'Bard'
            )[:speech]
          end
        end
      end

      context 'when role specified' do
        it 'should provide a build for a champion' do
          post action, params
          expect(speech).to eq "The highest win rate build for Bard Support is Boots of Mobility, Sightstone, Frost Queen's Claim, Redemption, Knight's Vow, Locket of the Iron Solari"
        end
      end
    end

    context 'when invalid role specified' do
      it 'should return the do not play response' do
        champion_params = params['result']['parameters']
        champion_params['lane'] = 'Top'

        post action, params
        expect(speech).to eq controller.send(
          :do_not_play_response,
          champion_params['champion'],
          champion_params['lane']
        )[:speech]
      end
    end
  end

  describe 'POST ability_order' do
    let(:action) { :ability_order }

    context 'when valid role specified' do
      context 'with repeated 3 starting abililties' do
        it 'should return the 4 first order and max order for abilities' do
          post action, params
          expect(speech).to eq(
          "The highest win rate on Azir Middle has you start W, Q, Q, E and then max Q, W, E"
          )
        end
      end

      context 'with uniq starting 3 abilities' do
        it 'should return the 3 first order and max order for abilities' do
          champion = RiotApi::RiotApi.get_champion('Azir')
          order = champion[:champion_gg].first[:skills][:highestWinPercent][:order]
          order[2] = 'E'
          order[3] = 'Q'
          allow(RiotApi::RiotApi).to receive(:get_champion).and_return(champion)
          post action, params
          expect(speech).to eq(
            "The highest win rate on Azir Middle has you start W, Q, E and then max Q, W, E"
          )
        end
      end
    end

    context 'when invalid role specified' do
      it 'should return the do not play response' do
        champion_params = params['result']['parameters']
        champion_params['lane'] = 'Support'

        post action, params
        expect(speech).to eq controller.send(
          :do_not_play_response,
          champion_params['champion'],
          champion_params['lane']
        )[:speech]
      end
    end
  end

  describe 'POST matchup' do
    let(:action) { :matchup }

    context 'when valid role specified' do
      it 'should return the best counters for the champion' do
        post action, params
        expect(speech).to eq(
          "The best counters for Jayce Top are Jarvan IV at 58.19% win rate, Sion at 56.3% win rate, Nautilus at 60.3% win rate"
        )
      end
    end

    context 'when invalid role specified' do
      it 'should return the do not play response' do
        champion_params = params['result']['parameters']
        champion = RiotApi::RiotApi.get_champion(champion_params['champion'])
        champion_params['lane'] = 'Support'

        post action, params
        expect(speech).to eq controller.send(
          :do_not_play_response,
          champion[:name],
          champion_params['lane']
        )[:speech]
      end
    end
  end

  describe 'POST lane' do
    let(:action) { :lane }

    context 'when valid role specified' do
      it 'should indicate the strength of champions in the given lane' do
        post action, params

        expect(speech).to eq(
          "Jax got better in the last patch and is currently ranked 41 with a 49.69% win rate and a 3.76% play rate as Top."
        )
      end
    end

    context 'when invalid role specified' do
      it 'should return the do not play response' do
        champion_params = params['result']['parameters']
        champion = RiotApi::RiotApi.get_champion(champion_params['champion'])
        champion_params['lane'] = 'Support'

        post action, params
        expect(speech).to eq controller.send(
          :do_not_play_response,
          champion[:name],
          champion_params['lane']
        )[:speech]
      end
    end
  end

  describe 'POST ability' do
    let(:action) { :ability }

    it "should describe the champion's ability" do
      post action, params

      expect(speech).to eq(
        "Ivern's second ability is called Brushmaker. In brush, Ivern's attacks are ranged and deal bonus magic damage. Ivern can activate this ability to create a patch of brush."
      )
    end
  end

  describe 'POST cooldown' do
    let(:action) { :cooldown }

    it "should provide the champion's cooldown" do
      post action, params

      expect(speech).to eq(
        "Yasuo's fourth ability, Last Breath, has a cooldown of 0 seconds at rank 3."
      )
    end
  end

  describe 'POST description' do
    let(:action) { :description }

    it 'should provide a description for the champion' do
      post action, params

      expect(speech).to eq(
        "Katarina, the the Sinister Blade, is a Assassin and Mage."
      )
    end
  end

  describe 'POST ally_tips' do
    let(:action) { :ally_tips }

    it 'should provide tips for playing the champion' do
      champion = RiotApi::RiotApi.get_champion('Fiora')
      allow(RiotApi::RiotApi).to receive(:get_champion).and_return(champion)
      allow(champion[:allytips]).to receive(:sample).and_return(
        champion[:allytips].last
      )
      post action, params

      expect(speech).to eq(
        "Here's a tip for playing as Fiora: Grand Challenge allows Fiora to take down even the most durable opponents and then recover if successful, so do not hesitate to attack the enemy's front line."
      )
    end
  end

  describe 'POST enemy_tips' do
    let(:action) { :enemy_tips }

    it 'should provide tips for beating the enemy champion' do
      champion = RiotApi::RiotApi.get_champion('Leblanc')
      allow(RiotApi::RiotApi).to receive(:get_champion).and_return(champion)
      allow(champion[:enemytips]).to receive(:sample).and_return(
        champion[:enemytips].last
      )
      post action, params

      expect(speech).to eq(
        "Here's a tip for playing against LeBlanc: Stunning or silencing LeBlanc will prevent her from activating the return part of Distortion."
      )
    end
  end
end
