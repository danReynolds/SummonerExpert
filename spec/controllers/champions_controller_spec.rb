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

  shared_examples 'load champion' do
    it 'should load the champion' do
      expect(controller).to receive(:load_champion).and_call_original
      post action, params
    end
  end

  shared_examples 'verify role' do
    it 'should verify the role' do
      expect(controller).to receive(:verify_role).and_call_original
      post action, params
    end
  end

  describe '#find_by_role' do
    let(:champion) { Rails.cache.read(champions: 'Bard') }

    context 'with a role provided' do
      let(:role) { 'Support' }
      context 'with a matching role' do
        it 'should return the data for that role' do
          expect(controller.send(:find_by_role, champion, role)).to eq(
            champion[:champion_gg].first
          )
        end
      end

      context 'without a matching role' do
        let(:role) { 'Made up role' }

        it 'should return no data' do
          expect(controller.send(:find_by_role, champion, role)).to eq nil
        end
      end
    end

    context 'without a role provided' do
      let(:role) { '' }

      context 'with multiple roles' do
        before :each do
          champion[:champion_gg] << champion[:champion_gg].first
        end

        it 'should return no data' do
          expect(controller.send(:find_by_role, champion, role)).to eq nil
        end
      end

      context 'with only one role' do
        it 'should return the data for that role' do
          expect(controller.send(:find_by_role, champion, role)).to eq(
            champion[:champion_gg].first
          )
        end
      end
    end
  end

  describe '#verify_role' do
    let(:champion) { 'Bard' }

    context 'with role' do
      let(:role) { 'Support' }

      context 'with role data' do
        let(:role_data) {
          Rails.cache.read(champions: 'Bard')[:champion_gg].first
        }

        it 'should return the role data' do
          allow(controller).to receive(:champion_params).and_return({
            champion: champion,
            lane: role
          })
          expect(controller).to receive(:find_by_role).and_return(role_data)
          controller.send(:verify_role)
        end
      end

      context 'without role data' do
        it 'should return the do not play response' do
          allow(controller).to receive(:champion_params).and_return({
            champion: champion,
            lane: role
          })
          expect(controller).to receive(:find_by_role).and_return(nil)
          expect(controller).to receive(:render).with({
            json: controller.send(:do_not_play_response, nil, role)
          })
          expect(controller.send(:verify_role)).to eq false
        end
      end
    end

    context 'without role' do
      let(:role) { '' }

      context 'with only one role' do
        let(:role_data) {
          Rails.cache.read(champions: 'Bard')[:champion_gg].first
        }

        it 'should return the only role data' do
          allow(controller).to receive(:champion_params).and_return({
            champion: champion
          })
          expect(controller).to receive(:find_by_role).and_return(role_data)
          controller.send(:verify_role)
        end
      end

      context 'with multiple roles' do
        it 'should return the ask for role response' do
          allow(controller).to receive(:champion_params).and_return({
            champion: champion
          })
          expect(controller).to receive(:find_by_role).and_return(nil)
          expect(controller).to receive(:render).with({
            json: controller.send(:ask_for_role_response)
          })
          expect(controller.send(:verify_role)).to eq false
        end
      end
    end
  end

  describe '#load_champion' do
    context 'with exact champion name' do
      it 'should load the champion' do
        allow(controller).to receive(:champion_params).and_return({
          champion: 'Bard'
        })
        expect(controller.send(:load_champion)).to eq 'Bard'
      end
    end

    context 'with similar champion name' do
      it 'should load the champion' do
        allow(controller).to receive(:champion_params).and_return({
          champion: 'Bardo'
        })
        expect(controller.send(:load_champion)).to eq 'Bard'
      end
    end

    context 'with dissimilar champion name' do
      it 'should respond with champion not found' do
        allow(controller).to receive(:champion_params).and_return({
          champion: 'This is not a valid name'
        })
        expect(controller).to receive(:render).with({
          json: controller.send(
            :champion_not_found_response, 'This is not a valid name'
          )
        })
        expect(controller.send(:load_champion)).to eq false
      end
    end
  end

  describe 'POST ranking' do
    let(:action) { :ranking }

    before :each do
      allow(controller).to receive(:champion_params).and_return(
        list_size: '3',
        lane: 'Top',
        list_position: '1',
        list_order: 'best'
      )
    end

    context 'with worst order' do
      before :each do
        allow(controller).to receive(:champion_params).and_return(
          list_size: '1',
          lane: 'Support',
          list_position: '1',
          list_order: 'worst'
        )
      end

      it 'should determine the worst champions' do
        post action, params
        expect(speech).to eq 'The worst champion in Support is Nunu.'
      end
    end

    context 'with tag' do
      before :each do
        allow(controller).to receive(:champion_params).and_return(
          list_size: '3',
          lane: 'Top',
          list_position: '1',
          list_order: 'best',
          tag: 'Assassin'
        )
      end

      it 'should filter the ranking of the champions by the provided tag' do
        post action, params
        expect(speech).to eq 'The best three champions in Top are Irelia, Yasuo, and Fiora.'
      end
    end

    context 'with list position specified' do
      before :each do
        allow(controller).to receive(:champion_params).and_return(
          list_size: '1',
          list_order: 'best',
          lane: 'Top',
          list_position: '2'
        )
      end

      it 'should determine the best champion at that list position' do
        post action, params
        expect(speech).to eq 'The second best champion in Top is Nasus.'
      end
    end

    context 'with multiple list size specified' do
      it 'determine the best champions for the specified list size and role' do
        post action, params
        expect(speech).to eq "The best three champions in Top are Darius, Nasus, and Jayce."
      end
    end

    context 'with single list size specified' do
      before :each do
        allow(controller).to receive(:champion_params).and_return(
          list_size: '1',
          list_position: '1',
          list_order: 'best',
          lane: 'Top'
        )
      end

      it 'determine the best champion for the specified role' do
        post action, params
        expect(speech).to eq "The best champion in Top is Darius."
      end
    end
  end

  describe 'POST matchup' do
    let(:action) { :matchup }
    let(:champion_name) { 'Azir' }
    let(:other_champion_name) { 'Heimerdinger' }

    before :each do
      allow(controller).to receive(:champion_params).and_return(
        champion: champion_name,
        champion1: other_champion_name,
        lane: role
      )
    end

    context 'without a role specified' do
      let(:role) { '' }

      context 'with no shared roles' do
        let(:response_text) {
          "Azir and Heimerdinger do not typically play against eachother in any role."
        }
        before :each do
          @champion = RiotApi::RiotApi.get_champion(champion_name)
          @champion[:champion_gg] = @champion[:champion_gg].first(1)
          @other_champion = RiotApi::RiotApi.get_champion(other_champion_name)
          @other_champion[:champion_gg] = @other_champion[:champion_gg].first(1)

          @champion[:champion_gg].first[:role] = 'Top'
          @other_champion[:champion_gg].first[:role] = 'Middle'

          allow(RiotApi::RiotApi).to receive(:get_champion)
            .and_return(@champion, @other_champion)
        end

        it_should_behave_like 'load champion'

        it 'should indicate that the two champions do not play against eachother' do
          post action, params
          expect(speech).to eq response_text
        end
      end

      context 'with a single shared role' do
        let(:response_text) {
          'Azir got worse against Heimerdinger in the latest patch and has a win rate of 37.93% against the Revered Inventor in Middle.'
        }
        before :each do
          @champion = RiotApi::RiotApi.get_champion(champion_name)
          @champion[:champion_gg] = @champion[:champion_gg].first(1)
          @other_champion = RiotApi::RiotApi.get_champion(other_champion_name)
          @other_champion[:champion_gg] = @other_champion[:champion_gg].first(1)

          role = 'Middle'
          @champion[:champion_gg].first[:role] = role
          @other_champion[:champion_gg].first[:role] = role

          allow(RiotApi::RiotApi).to receive(:get_champion)
            .and_return(@champion, @other_champion)
        end

        it 'should decide that the higher win rate champion should win' do
          post action, params
          expect(speech).to eq response_text
        end
      end

      context 'with multiple shared roles' do
        before :each do
          champion = RiotApi::RiotApi.get_champion(champion_name)
          first_role_data = champion[:champion_gg].first
          first_role_data[:role] = 'Middle'
          second_role_data = first_role_data.dup
          second_role_data[:role] = 'Top'
          champion[:champion_gg] = [first_role_data, second_role_data]

          other_champion = RiotApi::RiotApi.get_champion(other_champion_name)
          first_role_data = other_champion[:champion_gg].first
          first_role_data[:role] = 'Middle'
          second_role_data = first_role_data.dup
          second_role_data[:role] = 'Top'
          other_champion[:champion_gg] = [first_role_data, second_role_data]

          allow(RiotApi::RiotApi).to receive(:get_champion)
            .and_return(champion, other_champion)
        end

        it_should_behave_like 'load champion'

        it 'shoud ask for a role to be specified' do
          post action, params
          expect(speech).to eq controller.send(:ask_for_role_response)[:speech]
        end
      end
    end

    context 'with a role specified' do
      let(:role) { 'Middle' }

      context 'with both champions sharing the role' do
        let(:response_text) {
          "Azir got worse against Heimerdinger in the latest patch and has a win rate of 37.93% against the Revered Inventor in Middle."
        }

        before :each do
          champion = RiotApi::RiotApi.get_champion(champion_name)
          champion[:champion_gg].first[:role] = role
          other_champion = RiotApi::RiotApi.get_champion(other_champion_name)
          other_champion[:champion_gg].first[:role] = role

          allow(RiotApi::RiotApi).to receive(:get_champion)
            .and_return(champion, other_champion)
        end

        it 'should decide that the higher win rate champion should win' do
          post action, params
          expect(speech).to eq response_text
        end
      end

      context 'without both champions sharing the role' do
        let(:response_text) {
          "Azir and Heimerdinger do not typically play against eachother in Middle."
        }
        before :each do
          champion = RiotApi::RiotApi.get_champion(champion_name)
          champion[:champion_gg] = []
          other_champion = RiotApi::RiotApi.get_champion(other_champion_name)
          other_champion[:champion_gg] = []

          allow(RiotApi::RiotApi).to receive(:get_champion)
            .and_return(champion, other_champion)
        end

        it 'should indicate that the two champions do not play together' do
          post action, params
          expect(speech).to eq response_text
        end
      end
    end
  end

  describe 'POST title' do
    let(:action) { :title }
    let(:response_text) { "Sona's title is Maven of the Strings." }

    it_should_behave_like 'load champion'

    it 'should return the champions title' do
      post action, params
      expect(speech).to eq response_text
    end
  end

  describe 'POST stats' do
    let(:action) { :stats }
    let(:response_text) { 'Zed has 68 attack damage at level 5.' }

    it_should_behave_like 'load champion'

    context 'with stat modifier' do
      context 'with level specified' do
        it 'should calculate the stat for the champion' do
          post action, params
          expect(speech).to eq response_text
        end
      end

      context 'without level specified' do
        before :each do
          allow(controller).to receive(:champion_params).and_return(
            champion: 'Zed',
            stat: 'attackdamage'
          )
        end

        it 'should ask for the level' do
          post action, params
          expect(speech).to eq controller.send(:ask_for_level_response)[:speech]
        end
      end
    end

    context 'without stat modifier' do
      let(:response_text) { 'Zed has 345 movement speed.' }
      before :each do
        allow(controller).to receive(:champion_params).and_return(
          champion: 'Zed',
          stat: 'movespeed'
        )
      end

      it 'should calculate the stat for the champion' do
        post action, params
        expect(speech).to eq response_text
      end
    end
  end

  describe 'POST build' do
    let(:action) { :build }
    let(:response_text) {
      "The highest win rate build for Bard Support is Boots of Mobility, Sightstone, Frost Queen's Claim, Redemption, Knight's Vow, and Locket of the Iron Solari."
    }

    it_should_behave_like 'verify role'
    it_should_behave_like 'load champion'

    it 'should provide a build for a champion' do
      post action, params
      expect(speech).to eq response_text
    end
  end

  describe 'POST ability_order' do
    let(:action) { :ability_order }
    let(:response_text) {
      "The highest win rate on Azir Middle has you start W, Q, Q, E and then max Q, W, E."
    }

    it_should_behave_like 'load champion'
    it_should_behave_like 'verify role'

    context 'with repeated 3 starting abililties' do
      it 'should return the 4 first order and max order for abilities' do
        post action, params
        expect(speech).to eq response_text
      end
    end

    context 'with uniq starting 3 abilities' do
      let(:response_text) {
        "The highest win rate on Azir Middle has you start W, Q, E and then max Q, W, E."
      }

      it 'should return the 3 first order and max order for abilities' do
        champion = RiotApi::RiotApi.get_champion('Azir')
        order = champion[:champion_gg].first[:skills][:highestWinPercent][:order]
        order[2] = 'E'
        order[3] = 'Q'
        allow(RiotApi::RiotApi).to receive(:get_champion).and_return(champion)
        post action, params
        expect(speech).to eq response_text
      end
    end
  end

  describe 'POST counters' do
    let(:action) { :counters }
    let(:response_text) {
      "The best three counters for Jayce Top are Jarvan IV at a 58.19% win rate, Sion at a 56.3% win rate, and Nautilus at a 60.3% win rate."
    }

    it_should_behave_like 'verify role'
    it_should_behave_like 'load champion'

    it 'should return the best counters for the champion' do
      post action, params
      expect(speech).to eq response_text
    end
  end

  describe 'POST lane' do
    let(:action) { :lane }
    let(:response_text) {
      "Jax got better in the last patch and is currently ranked forty-first with a 49.69% win rate and a 3.76% play rate as Top."
    }

    it_should_behave_like 'verify role'
    it_should_behave_like 'load champion'

    it 'should indicate the strength of champions in the given lane' do
      post action, params
      expect(speech).to eq(response_text)
    end
  end

  describe 'POST ability' do
    let(:action) { :ability }
    let(:response_text) {
      "Ivern's second ability is called Brushmaker. In brush, Ivern's attacks are ranged and deal bonus magic damage. Ivern can activate this ability to create a patch of brush."
    }

    it_should_behave_like 'load champion'

    it "should describe the champion's ability" do
      post action, params

      expect(speech).to eq response_text
    end
  end

  describe 'POST cooldown' do
    let(:action) { :cooldown }
    let(:response_text) {
      "Yasuo's fourth ability, Last Breath, has a cooldown of 0 seconds at rank 3."
    }

    it_should_behave_like 'load champion'

    it "should provide the champion's cooldown" do
      post action, params
      expect(speech).to eq response_text
    end
  end

  describe 'POST description' do
    let(:action) { :description }
    let(:response_text) {
      "Katarina, the the Sinister Blade, is an Assassin and a Mage and is played as Middle."
    }

    it 'should provide a description for the champion' do
      post action, params
      expect(speech).to eq response_text
    end
  end

  describe 'POST ally_tips' do
    let(:action) { :ally_tips }
    let(:response_text) {
      "Here's a tip for playing as Fiora: Grand Challenge allows Fiora to take down even the most durable opponents and then recover if successful, so do not hesitate to attack the enemy's front line."
    }

    it_should_behave_like 'load champion'

    it 'should provide tips for playing the champion' do
      champion = RiotApi::RiotApi.get_champion('Fiora')
      allow(RiotApi::RiotApi).to receive(:get_champion).and_return(champion)
      allow(champion[:allytips]).to receive(:sample).and_return(
        champion[:allytips].last
      )

      post action, params
      expect(speech).to eq response_text
    end
  end

  describe 'POST enemy_tips' do
    let(:action) { :enemy_tips }
    let(:response_text) {
      "Here's a tip for playing against LeBlanc: Stunning or silencing LeBlanc will prevent her from activating the return part of Distortion."
    }

    it_should_behave_like 'load champion'

    it 'should provide tips for beating the enemy champion' do
      champion = RiotApi::RiotApi.get_champion('Leblanc')
      allow(RiotApi::RiotApi).to receive(:get_champion).and_return(champion)
      allow(champion[:enemytips]).to receive(:sample).and_return(
        champion[:enemytips].last
      )

      post action, params
      expect(speech).to eq response_text
    end
  end
end
