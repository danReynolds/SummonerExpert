require 'rails_helper'
require 'spec_contexts.rb'

describe ChampionsController, type: :controller do
  include_context 'spec setup'
  include_context 'determinate speech'

  before :each do
    allow(controller).to receive(:champion_params).and_return(champion_params)
  end

  describe 'POST roles' do
    let(:action) { :roles }
    let(:champion_params) do
      {
        name: 'Jax',
        elo: 'GOLD'
      }
    end

    it 'should list the roles the champion plays in that elo' do
      post action, params: params
      expect(speech).to eq 'Jax is best suited to Top and Jungle in Gold division.'
    end
  end

  describe 'POST ranking' do
    let(:action) { :ranking }
    let(:champion_params) do
      {
        list_size: '3',
        role: 'TOP',
        list_position: '1',
        list_order: 'highest',
        elo: 'SILVER',
        position: 'kills'
      }
    end
    let(:query_params) do
      { position: 'kills', elo: 'SILVER', role: 'TOP' }
    end

    it 'should rank the champions by the specified position' do
      champion_params[:position] = 'deaths'
      post action, params: params
      expect(speech).to eq 'The three champions with the highest deaths playing Top in Silver division are Rengar, Yasuo, and Quinn.'
    end

    it 'should sort the champions by the specified ordering' do
      champion_params[:list_order] = 'lowest'
      post action, params: params
      expect(speech).to eq 'The three champions with the lowest kills playing Top in Silver division are Nautilus, Galio, and Maokai.'
    end

    context 'with no champions returned' do
      let(:champion) { Champion.new(name: 'Bard') }

      context 'with normal list position' do
        before :each do
          allow(Rails.cache).to receive(:read).with(query_params).and_return([])
          allow(Rails.cache).to receive(:read).with('champions').and_call_original
        end

        context 'with complete champions returned' do
          before :each do
            champion_params[:list_size] = '0'
          end

          it 'should indicate that 0 champions were requested' do
            post action, params: params
            expect(speech).to eq 'No champions were requested.'
          end
        end

        context 'with incomplete champions returned' do
          it 'should indicate that there are no champions for that role and elo' do
            post action, params: params
            expect(speech).to eq 'There are no champions available playing Top in Silver division in the current patch.'
          end
        end
      end

      context 'with offset list position' do
        before :each do
          champion_params[:list_position] = '2'
        end

        context 'with complete champions returned' do
          before :each do
            champion_params[:list_size] = '0'
          end

          it 'should indicate that 0 champions were requested' do
            post action, params: params
            expect(speech).to eq 'No champions were requested.'
          end
        end

        context 'with incomplete champions returned' do
          before :each do
            allow(Rails.cache).to receive(:read).with(query_params).and_return(
              Rails.cache.read(query_params).first(1)
            )
            allow(Rails.cache).to receive(:read).with('champions').and_call_original
          end

          it 'should indicate that there are no champions for that role and elo at that position' do
            post action, params: params
            expect(speech).to eq 'The current patch only has information for one champion playing Top in Silver division. There are no champions beginning at the second position.'
          end
        end
      end
    end

    context 'with single champion returned' do
      context 'with normal list position' do
        before :each do
          allow(Rails.cache).to receive(:read).with(query_params).and_return(
            Rails.cache.read(query_params).first(1)
          )
          allow(Rails.cache).to receive(:read).with('champions').and_call_original
          champion_params[:list_size] = '1'
        end

        context 'with complete champions returned' do
          it 'should return the champion' do
            post action, params: params
            expect(speech).to eq 'The champion with the highest kills playing Top in Silver division is Talon.'
          end
        end

        context 'with incomplete champions returned' do
          before :each do
            allow(Rails.cache).to receive(:read).with(query_params).and_return([])
            allow(Rails.cache).to receive(:read).with('champions').and_call_original
          end

          it 'should indicate that there are not enough champions' do
            post action, params: params
            expect(speech).to eq 'There are no champions available playing Top in Silver division in the current patch.'
          end
        end
      end

      context 'with offset list position' do
        before :each do
          allow(Rails.cache).to receive(:read).with(query_params).and_return(
            Rails.cache.read(query_params).first(2)
          )
          allow(Rails.cache).to receive(:read).with('champions').and_call_original
          champion_params[:list_size] = '1'
          champion_params[:list_position] = '2'
        end

        context 'with complete champions returned' do
          it 'should return the champion' do
            post action, params: params
            expect(speech).to eq 'The champion with the second highest kills playing Top in Silver division is Rengar.'
          end
        end

        context 'with incomplete champions returned' do
          before :each do
            allow(Rails.cache).to receive(:read).with(query_params).and_return([])
            allow(Rails.cache).to receive(:read).with('champions').and_call_original
          end

          it 'should indicate that there are not enough champions' do
            post action, params: params
            expect(speech).to eq 'The current patch only has information for zero champions playing Top in Silver division. There are no champions beginning at the second position.'
          end
        end
      end
    end

    context 'with multiple champions returned' do
      before :each do
        champion_params[:list_size] = '5'
      end

      context 'with normal list position' do
        context 'with complete champions returned' do
          it 'should return the champions' do
            post action, params: params
            expect(speech).to eq 'The five champions with the highest kills playing Top in Silver division are Talon, Rengar, Quinn, Pantheon, and Akali.'
          end
        end

        context 'with incomplete champions returned' do
          before :each do
            allow(Rails.cache).to receive(:read).with(query_params).and_return(
              Rails.cache.read(query_params).first(3)
            )
            allow(Rails.cache).to receive(:read).with('champions').and_call_original
          end

          it 'should indicate that there are not enough champions' do
            post action, params: params
            expect(speech).to eq 'The current patch only has enough data for three champions. The three champions with the highest kills playing Top in Silver division are Talon, Rengar, and Quinn.'
          end
        end
      end

      context 'with offset list position' do
        before :each do
          champion_params[:list_position] = '2'
        end

        context 'with complete champions returned' do
          it 'should return the champions' do
            post action, params: params
            expect(speech).to eq 'The second through sixth champions with the highest kills playing Top in Silver division are Rengar, Quinn, Pantheon, Akali, and Wukong.'
          end
        end

        context 'with incomplete champions returned' do
          before :each do
            allow(Rails.cache).to receive(:read).with(query_params).and_return(
              Rails.cache.read(query_params).first(3)
            )
            allow(Rails.cache).to receive(:read).with('champions').and_call_original
          end

          it 'should indicate that there are not enough champions' do
            post action, params: params
            expect(speech).to eq 'The current patch only has enough data for three champions. The second through third champions with the highest kills playing Top in Silver division are Rengar and Quinn.'
          end
        end
      end
    end
  end

  describe 'POST stats' do
    let(:action) { :stats }
    let(:champion_params) do
      {
        stat: 'armor',
        name: 'Nocturne',
        level: '5'
      }
    end

    context 'with a valid level' do
      it "should specify the champion's stat value at the given level" do
        post action, params: params
        expect(speech).to eq 'Nocturne has 40.88 armor at level 5.'
      end
    end

    context 'with a stat that does not gain per level' do
      before :each do
        champion_params[:stat] = :movespeed
      end

      it 'should not factor in the stat per level' do
        post action, params: params
        expect(speech).to eq 'Nocturne has 345.0 movement speed at level 5.'
      end
    end

    context 'with an invalid level' do
      before :each do
        champion_params[:level] = '25'
      end

      it 'should respond indicating that the level is invalid' do
        post action, params: params
        expect(speech).to eq 'A valid champion level is between 1 and 18, at least for now.'
      end
    end
  end

  describe 'POST ability_order' do
    let(:action) { :ability_order }
    let(:champion_params) do
      {
        name: 'Azir',
        role: 'MIDDLE',
        elo: 'GOLD',
        metric: 'highestCount'
      }
    end

    it 'should not repeat the order if they are the same' do
      champion_params.merge!({
        name: 'Shyvana',
        role: 'JUNGLE',
        elo: 'SILVER',
        metric: 'highestCount'
      })
      post action, params: params
      expect(speech).to eq 'The most frequent ability order for Shyvana Jungle in Silver is to both start and max W, Q, E.'
    end

    it 'should indicate the ability ordering for the champion' do
      post action, params: params
      expect(speech).to eq 'The most frequent ability order for Azir Middle in Gold is to start W, Q, E and then max Q, W, E.'
    end

    it 'should vary the ability ordering by metric' do
      champion_params[:metric] = 'highestWinrate'
      post action, params: params

      expect(speech).to eq 'The highest win rate ability order for Azir Middle in Gold is to start W, Q, E and then max Q, W, E.'
    end
  end

  describe 'POST build' do
    let(:action) { :build }
    let(:champion_params) do
      {
        name: 'Bard',
        role: 'SUPPORT',
        elo: 'GOLD',
        metric: 'highestCount'
      }
    end

    it 'should determine the best build for the champion' do
      post action, params: params
      expect(speech).to eq "The most frequent build for Bard Support in Gold division is Boots of Mobility, Eye of the Watchers, Redemption, Locket of the Iron Solari, Knight's Vow, and Mikael's Crucible."
    end

    it 'should vary the build based on the specified metric' do
      champion_params[:metric] = 'highestWinrate'
      post action, params: params
      expect(speech).to eq "The highest win rate build for Bard Support in Gold division is Boots of Swiftness, Eye of the Watchers, Redemption, Locket of the Iron Solari, Knight's Vow, and Zz'Rot Portal."
    end
  end

  describe 'POST matchup' do
    let(:action) { :matchup }
    let(:champion_params) do
      {
        name1: 'Shyvana',
        name2: 'Nocturne',
        role1: 'JUNGLE',
        role2: 'JUNGLE',
        elo: 'GOLD',
        matchup_position: 'kills'
      }
    end

    context 'error messages' do
      context 'duo role no matchup' do
        let(:champion_params) do
          {
            name1: 'Jinx',
            name2: 'Nocturne',
            role1: 'JUNGLE',
            role2: 'JUNGLE',
            elo: 'GOLD',
            matchup_position: 'kills'
          }
        end

        it 'should indicate that the champions do not play together' do
          post action, params: params
          expect(speech).to eq 'I do not have any information on matchups for Jinx Jungle and Nocturne Jungle playing together in Gold division. I would ship them though.'
        end
      end

      context 'single role no matchup' do
        let(:champion_params) do
          {
            name1: 'Jinx',
            name2: 'Nocturne',
            role1: 'JUNGLE',
            role2: '',
            elo: 'GOLD',
            matchup_position: 'kills'
          }
        end

        it 'should indicate that the champions do not play together' do
          post action, params: params
          expect(speech).to eq 'I cannot find any matchup information on Jinx and Nocturne playing Jungle in Gold division.'
        end
      end

      context 'multiple shared roles' do
        let(:champion_params) do
          {
            name1: 'Jinx',
            name2: 'Bard',
            role1: '',
            role2: '',
            elo: 'GOLD',
            matchup_position: 'kills'
          }
        end

        it 'should indicate that the champions play together in multiple roles' do
          post action, params: params
          expect(response_body.dig(:data, :google, :expect_user_response)).to eq true
          expect(speech).to eq 'Jinx and Bard have matchups for multiple roles in Gold division. Please specify roles for one or both champions.'
        end
      end
    end

    context 'no shared roles' do
      let(:champion_params) do
        {
          name1: 'Jinx',
          name2: 'Darius',
          role1: '',
          role2: '',
          elo: 'GOLD',
          matchup_position: 'kills'
        }
      end

      it 'should indicate that the champions do not have any shared roles' do
        post action, params: params
        expect(speech).to eq 'I cannot find matchup information for Jinx and Darius playing together for any role combination in Gold division.'
      end
    end

    context 'with solo role' do
      before :each do
        champion_params[:role1] = ''
      end

      context 'with general matchup position' do
        it 'should return the matchup for the champions' do
          post action, params: params
          expect(speech).to eq 'Shyvana and Nocturne have 6.05 and 7.48 kills respectively playing Jungle in Gold division.'
        end
      end

      context 'with winrate matchup position' do
        before :each do
          champion_params[:matchup_position] = 'winrate'
        end

        it 'should return the matchup for the champions' do
          post action, params: params
          expect(speech).to eq 'Last I heard, Shyvana has a 50.21% win rate against Nocturne playing Jungle in Gold division.'
        end
      end
    end

    context 'with duo role' do
      context 'with general matchup position' do
        it 'should return the matchup for the champions' do
          post action, params: params
          expect(speech).to eq 'Shyvana and Nocturne have 6.05 and 7.48 kills respectively playing Jungle in Gold division.'
        end
      end

      context 'with winrate matchup position' do
        before :each do
          champion_params[:matchup_position] = 'winrate'
        end

        it 'should return the matchup for the champions' do
          post action, params: params
          expect(speech).to eq 'Last I heard, Shyvana has a 50.21% win rate against Nocturne playing Jungle in Gold division.'
        end
      end
    end

    context 'with synergy role' do
      before :each do
        champion_params[:name1] = 'Bard'
        champion_params[:name2] = 'Jinx'
        champion_params[:role1] = 'SYNERGY'
      end

      context 'with general matchup position' do
        it 'should return the matchup for the champions' do
          post action, params: params
          expect(speech).to eq 'Bard averages 3.29 kills in Support when playing with Jinx Adc in Gold.'
        end
      end

      context 'with winrate matchup position' do
        before :each do
          champion_params[:matchup_position] = 'winrate'
        end

        it 'should return the matchup for the champions' do
          post action, params: params
          expect(speech).to eq 'Bard averages a 50.83% win rate in Support when playing alongside Jinx Adc in Gold.'
        end
      end
    end
  end

  describe 'POST matchup_ranking' do
    let(:action) { :matchup_ranking }
    let(:champion_params) do
      {
        name: 'Shyvana',
        role1: 'JUNGLE',
        role2: 'JUNGLE',
        elo: 'GOLD',
        list_order: 'highest',
        list_position: '1',
        list_size: '1',
        matchup_position: 'winrate'
      }
    end
    let(:query_params) do
      { matchups: { name: 'Shyvana', role: 'JUNGLE', elo: 'GOLD' } }
    end

    context 'with both roles specified' do
      context 'with both roles the same' do
        it 'should return the matchups for that role combination' do
          post action, params: params
          expect(speech).to eq "The champion with the highest win rate playing Jungle against Shyvana from Gold division is Cho'Gath."
        end
      end

      context 'with either role synergy' do
        before :each do
          champion_params[:role1] = 'SYNERGY'
          champion_params[:name] = 'Sivir'
        end

        it 'should return the matchups for the synergy role' do
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Support with Sivir Adc from Gold division is Sion.'
        end
      end

      context 'with either role adc support' do
        before :each do
          champion_params[:role1] = 'ADCSUPPORT'
          champion_params[:name] = 'Blitzcrank'
        end

        it 'should return the matchups for the adcsupport role' do
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Adc against Blitzcrank Support from Gold division is Quinn.'
        end
      end

      context 'with one role ADC and one SUPPORT' do
        before :each do
          champion_params[:role1] = 'ADC'
          champion_params[:role2] = 'SUPPORT'
          champion_params[:name] = 'Jhin'
        end
        it 'should return the matchups for the synergy role' do
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Support against Jhin Adc from Gold division is Taric.'
        end
      end
    end

    context 'with no role specified' do
      before :each do
        champion_params[:role1] = ''
        champion_params[:role2] = ''
      end

      context 'with only one role played by the champion' do
        it 'should return the complete list of champions' do
          post action, params: params
          expect(speech).to eq "The champion with the highest win rate playing Jungle against Shyvana from Gold division is Cho'Gath."
        end
      end

      context 'with a bot lane champion' do
        before :each do
          champion_params[:name] = 'Ashe'
        end

        it 'should determine the single role for the champion despite having other matchup roles' do
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Adc against Ashe from Gold division is Miss Fortune.'
        end
      end
    end

    context 'with only the named role specified' do
      before :each do
        champion_params[:role1] = 'JUNGLE'
        champion_params[:role2] = ''
      end

      it 'should use the named role to find the matchups' do
        post action, params: params
        expect(speech).to eq "The champion with the highest win rate playing Jungle against Shyvana from Gold division is Cho'Gath."
      end
    end

    context 'with only the unnamed role specified' do
      before :each do
        champion_params[:role1] = ''
      end

      context 'as a non-adc/support role' do
        it 'should use the unnamed role and return the complete list of champions' do
          post action, params: params
          expect(speech).to eq "The champion with the highest win rate playing Jungle against Shyvana from Gold division is Cho'Gath."
        end
      end

      context 'as a support role' do
        before :each do
          champion_params[:role1] = ''
          champion_params[:role2] = 'SUPPORT'
        end

        it 'should use the unnamed role to determine if the named champion is an ADC' do
          champion_params[:name] = 'Jinx'
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Support against Jinx from Gold division is Janna.'
        end

        it 'should use the unnamed role to determine if the named champion is a Support' do
          champion_params[:name] = 'Janna'
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Support against Janna from Gold division is Sona.'
        end
      end

      context 'as an ADC role' do
        before :each do
          champion_params[:role1] = ''
          champion_params[:role2] = 'ADC'
        end

        it 'should use the unnamed role to determine if the named champion is an ADC' do
          champion_params[:name] = 'Jinx'
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Adc against Jinx from Gold division is Miss Fortune.'
        end

        it 'should use the unnamed role to determine if the named champion is a Support' do
          champion_params[:name] = 'Janna'
          post action, params: params
          expect(speech).to eq 'The champion with the highest win rate playing Adc against Janna from Gold division is Miss Fortune.'
        end
      end
    end

    context 'error messages' do
      context 'empty matchup rankings' do
        context 'duo roles specified' do
          before :each do
            champion_params[:role1] = 'TOP'
            champion_params[:role2] = 'MIDDLE'
          end

          it 'should indicate that the champion has no matchup rankings for the given two roles' do
            post action, params: params
            expect(speech).to eq 'I have limited knowledge of champions playing Middle with Shyvana Top in Gold division. That would either be a terrible or great idea.'
          end
        end

        context 'only named role specified' do
          before :each do
            champion_params[:role2] = ''
          end

          context 'empty matchup rankings' do
            before :each do
              allow(Rails.cache).to receive(:read).and_return(nil)
            end

            it 'should indicate that the champion has no matchup rankings for the given role' do
              post action, params: params
              expect(speech).to eq 'I do not seem to have much information on Shyvana Jungle. It sounds like you are trying something off meta again.'
            end
          end
        end

        context 'only unnamed role specified' do
          before :each do
            champion_params[:role1] = ''
          end

          context 'empty matchup rankings' do
            before :each do
              allow(Rails.cache).to receive(:read).and_return(nil)
            end

            it 'should indicate that there are no matchup rankings for the unnamed role' do
              post action, params: params
              expect(speech).to eq 'I do not have any information for champions playing Jungle with Shyvana. Anything can happen though, I expect the season will be full of surprises.'
            end
          end
        end

        context 'no roles specified' do
          before :each do
            champion_params[:name] = 'Jinx'
            champion_params[:role1] = ''
            champion_params[:role2] = ''
          end

          it 'should ask for role specification' do
            post action, params: params
            expect(speech).to eq "The champion with the highest win rate playing Adc against Jinx from Gold division is Miss Fortune."
          end
        end
      end
    end

    context 'api responses' do
      context 'no champions returned' do
        context 'with normal position' do
          context 'with complete matchup rankings' do
            before :each do
              champion_params[:list_size] = '0'
            end

            it 'should indicate that no champions were requested' do
              post action, params: params
              expect(speech).to eq 'No champions were requested.'
            end
          end
        end

        context 'with offset position' do
          before :each do
            champion_params[:list_position] = '2'
          end

          context 'with complete matchup rankings' do
            before :each do
              champion_params[:list_size] = '0'
            end

            it 'should indicate that there were no champions requested' do
              post action, params: params
              expect(speech).to eq 'No champions were requested.'
            end
          end

          context 'with incomplete matchup rankings' do
            before :each do
              allow(Rails.cache).to receive(:read).with(query_params).and_return(
                Rails.cache.read(query_params).first(1)
              )
            end

            it 'should indicate that there are not enough champions when begun at that offset' do
              post action, params: params
              expect(speech).to eq 'The current patch only has data for one champion playing Jungle in Gold division. There are no champions beginning at the second position.'
            end
          end
        end
      end

      context 'with a single champion returned' do
        context 'with normal list position' do
          context 'with complete matchup rankings' do
            context 'with a shared role' do
              it 'should return the complete list of champions, specifying one role' do
                post action, params: params
                expect(speech).to eq "The champion with the highest win rate playing Jungle against Shyvana from Gold division is Cho'Gath."
              end
            end

            context 'with duo roles' do
              before :each do
                champion_params[:name] = 'Janna'
                champion_params[:role1] = 'SUPPORT'
                champion_params[:role2] = 'ADC'
              end

              it 'should return the complete list of champions, specifying both roles' do
                post action, params: params
                expect(speech).to eq 'The champion with the highest win rate playing Adc against Janna Support from Gold division is Miss Fortune.'
              end
            end

            context 'with synergy' do
              before :each do
                champion_params[:name] = 'Janna'
                champion_params[:role1] = 'SYNERGY'
                champion_params[:role2] = 'ADC'
              end

              it 'should return the complete list of champions, specifying that it is a synergy ranking' do
                post action, params: params
                expect(speech).to eq 'The champion with the highest win rate playing Adc with Janna Support from Gold division is Twitch.'
              end
            end
          end

          context 'with incomplete matchup rankings' do
            before :each do
              allow(Rails.cache).to receive(:read).with(query_params).and_return(
                Rails.cache.read(query_params).first(1)
              )
              champion_params[:list_size] = 2
            end

            it 'should return the partial list of champions, indicating that there are not enough' do
              post action, params: params
              expect(speech).to eq 'The current patch only has enough data for a single champion. The single champion with the highest win rate playing Jungle against Shyvana from Gold division is Lee Sin.'
            end
          end
        end

        context 'with offset list position' do
          before :each do
            champion_params[:list_position] = '2'
          end

          context 'with complete matchup rankings' do
            context 'with a shared role' do
              it 'should return the complete list of champions, indicating the offset and one role' do
                post action, params: params
                expect(speech).to eq 'The champion with the second highest win rate playing Jungle against Shyvana from Gold division is Kindred.'
              end
            end

            context 'with duo roles' do
              before :each do
                champion_params[:name] = 'Jinx'
                champion_params[:role1] = 'ADC'
                champion_params[:role2] = 'SUPPORT'
              end

              it 'should return the complete list of champions, indicating the offset and both roles' do
                post action, params: params
                expect(speech).to eq 'The champion with the second highest win rate playing Support against Jinx Adc from Gold division is Sion.'
              end
            end

            context 'with synergy role' do
              before :each do
                champion_params[:name] = 'Jinx'
                champion_params[:role1] = 'SYNERGY'
                champion_params[:role2] = 'SUPPORT'
              end

              it 'should return the complete list of champions, indicating the offset and specifying that it is a synergy role' do
                post action, params: params
                expect(speech).to eq 'The champion with the second highest win rate playing Support with Jinx Adc from Gold division is Sion.'
              end
            end
          end

          context 'with incomplete matchup rankings' do
            before :each do
              champion_params[:list_size] = '2'
            end

            before :each do
              allow(Rails.cache).to receive(:read).with(query_params).and_return(
                Rails.cache.read(query_params).first(2)
              )
            end

            it 'should return the incomplete list of champions, indicating the offset position' do
              post action, params: params
              expect(speech).to eq 'The current patch only has enough data for a single champion beginning at the second position. The single champion with the highest win rate playing Jungle against Shyvana from Gold division is Kayn.'
            end
          end
        end
      end

      context 'with multiple champions returned' do
        before :each do
          champion_params[:list_size] = '3'
        end

        context 'with normal list position' do
          context 'with complete matchup rankings' do
            context 'with a shared role' do
              it 'should return the complete list of champions, indicating the one shared role' do
                post action, params: params
                expect(speech).to eq "The champions with the highest win rate playing Jungle against Shyvana from Gold division are Cho'Gath, Kindred, and Nunu."
              end
            end

            context 'with duo roles' do
              before :each do
                champion_params[:role1] = 'ADC'
                champion_params[:role2] = 'SUPPORT'
                champion_params[:name] = 'Jinx'
              end

              it 'should return the complete list of champions, indicating the two roles' do
                post action, params: params
                expect(speech).to eq 'The champions with the highest win rate playing Support against Jinx Adc from Gold division are Janna, Sion, and Trundle.'
              end
            end

            context 'with synergy role' do
              before :each do
                champion_params[:role1] = 'ADC'
                champion_params[:role2] = 'SYNERGY'
                champion_params[:name] = 'Jinx'
              end

              it 'should return the complete list of champions, indicating they synergize' do
                post action, params: params
                expect(speech).to eq 'The champions with the highest win rate playing Support with Jinx Adc from Gold division are Poppy, Sion, and Janna.'
              end
            end
          end

          context 'with incomplete matchup rankings' do
            before :each do
              allow(Rails.cache).to receive(:read).with(query_params).and_return(
                Rails.cache.read(query_params).first(2)
              )
              allow(Rails.cache).to receive(:read).with(:champions).and_call_original
              allow(Rails.cache).to receive(:read).with('champions').and_call_original
              champion_params[:list_size] = 3
            end

            context 'with a shared role' do
              it 'should return the partial list of champions, indicating the one shared role' do
                post action, params: params
                expect(speech).to eq 'The current patch only has enough data for two champions. The two champions with the highest win rate playing Jungle against Shyvana from Gold division are Lee Sin and Kayn.'
              end
            end

            context 'with duo roles' do
              let(:query_params) do
                { matchups: { name: 'Jinx', role: 'ADCSUPPORT', elo: 'GOLD' } }
              end
              before :each do
                champion_params[:role1] = 'ADC'
                champion_params[:role2] = 'SUPPORT'
                champion_params[:name] = 'Jinx'
              end

              it 'should return the partial list of champions, indicating the multiple roles' do
                post action, params: params
                expect(speech).to eq 'The current patch only has enough data for two champions. The two champions with the highest win rate playing Support against Jinx Adc from Gold division are Blitzcrank and Thresh.'
              end
            end

            context 'with synergy role' do
              let(:query_params) do
                { matchups: { name: 'Jinx', role: 'SYNERGY', elo: 'GOLD' } }
              end
              before :each do
                champion_params[:role1] = 'ADC'
                champion_params[:role2] = 'SYNERGY'
                champion_params[:name] = 'Jinx'
              end

              it 'should return the partial list of champions, indicating the synergy role' do
                post action, params: params
                expect(speech).to eq 'The current patch only has enough data for two champions. The two champions with the highest win rate playing Support with Jinx Adc from Gold division are Blitzcrank and Thresh.'
              end
            end
          end

          context 'with offset list position' do
            before :each do
              champion_params[:list_position] = '2'
              champion_params[:list_size] = '4'
            end

            context 'with complete matchup rankings' do
              context 'with a shared role' do
                it 'should return the complete list of champions, specifying the offset and shared role' do
                  post action, params: params
                  expect(speech).to eq 'The second through fifth champions with the highest win rate playing Jungle against Shyvana from Gold division are Kindred, Nunu, Rammus, and Jax.'
                end
              end

              context 'with duo roles' do
                before :each do
                  champion_params[:name] = 'Janna'
                  champion_params[:role1] = 'SUPPORT'
                  champion_params[:role2] = 'ADC'
                end

                it 'should return the complete list of champions, specifying the offset and duo roles' do
                  post action, params: params
                  expect(speech).to eq 'The second through fifth champions with the highest win rate playing Adc against Janna Support from Gold division are Twitch, Tristana, Draven, and Jhin.'
                end
              end

              context 'with synergy role' do
                before :each do
                  champion_params[:name] = 'Janna'
                  champion_params[:role1] = 'SYNERGY'
                  champion_params[:role2] = 'ADC'
                end

                it 'should return the complete list of champions, specifying the offset and synergy role' do
                  post action, params: params
                  expect(speech).to eq 'The second through fifth champions with the highest win rate playing Adc with Janna Support from Gold division are Miss Fortune, Jinx, Tristana, and Draven.'
                end
              end
            end

            context 'with incomplete matchup rankings' do
              before :each do
                allow(Rails.cache).to receive(:read).with(query_params).and_return(
                  Rails.cache.read(query_params).first(3)
                )
                allow(Rails.cache).to receive(:read).with(:champions).and_call_original
                allow(Rails.cache).to receive(:read).with('champions').and_call_original
              end
              context 'with a shared role' do
                it 'should return the partial list of champions, specifying the offset and shared role' do
                  post action, params: params
                  expect(speech).to eq 'The current patch only has enough data for three champions. The second through third champions with the highest win rate playing Jungle against Shyvana from Gold division are Lee Sin and Kayn.'
                end
              end

              context 'with duo roles' do
                let(:query_params) do
                  { matchups: { name: 'Jinx', role: 'ADCSUPPORT', elo: 'GOLD' } }
                end
                before :each do
                  champion_params[:role1] = 'ADC'
                  champion_params[:role2] = 'SUPPORT'
                  champion_params[:name] = 'Jinx'
                end

                it 'should return the partial list of champions, specifying the offset and duo roles' do
                  post action, params: params
                  expect(speech).to eq 'The current patch only has enough data for three champions. The second through third champions with the highest win rate playing Support against Jinx Adc from Gold division are Blitzcrank and Thresh.'
                end
              end

              context 'with synergy role' do
                let(:query_params) do
                  { matchups: { name: 'Jinx', role: 'SYNERGY', elo: 'GOLD' } }
                end
                before :each do
                  champion_params[:role1] = 'ADC'
                  champion_params[:role2] = 'SYNERGY'
                  champion_params[:name] = 'Jinx'
                end

                it 'should return the partial list of champions, specifying the offset and synergy role' do
                  post action, params: params
                  expect(speech).to eq 'The current patch only has enough data for three champions. The second through third champions with the highest win rate playing Support with Jinx Adc from Gold division are Thresh and Lulu.'
                end
              end
            end
          end
        end
      end
    end
  end

  describe 'POST role_performance' do
    let(:action) { :role_performance }
    let(:champion_params) do
      {
        name: 'Thresh',
        role: 'SUPPORT',
        elo: 'BRONZE',
        position_details: 'goldEarned'
      }
    end

    context 'with a damage composition position' do
      before(:each) do
        champion_params[:position_details] = :total
      end

      it 'should give the damage composition value' do
        post action, params: params
        expect(speech).to eq 'Thresh averages 8851.59 total damage dealt playing Support in Bronze division.'
      end
    end

    context 'with no position details' do
      before(:each) do
        champion_params[:position_details] = ''
      end

      it 'should ask for position details' do
        post action, params: params
        expect(speech).to eq 'Please specify the information you want to know about Thresh Support.'
      end
    end

    context 'with an absolute position details' do
      it "should indicate the champion's absolute value for the given position" do
        post action, params: params
        expect(speech).to eq 'Thresh averages 9345.97 gold earned playing Support in Bronze division.'
      end
    end

    context 'with a percentage position details' do
      before(:each) do
        champion_params[:positionDetails] = :banRate
      end

      it "should indicate the champion's percentage value for the given position" do
        post action, params: params
        expect(speech).to eq 'Thresh averages 9345.97 gold earned playing Support in Bronze division.'
      end
    end
  end

  describe 'POST role_performance_summary' do
    let(:action) { :role_performance_summary }
    let(:champion_params) do
      {
        name: 'Shyvana',
        role: 'JUNGLE',
        elo: 'GOLD',
      }
    end

    context 'with no previous performance' do
      before(:each) do
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:overallPerformanceScore).and_call_original
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:previousOverallPerformanceScore).and_return({})
      end

      it 'should indicate that the champion has been introduced' do
        post action, params: params
        expect(speech).to eq 'Shyvana is new this patch in Jungle and is ranked 8th out of 45 with a 6.1/5.28/6.86 KDA, 51.87% win rate and a 0.02% ban rate in Gold division.'
      end
    end

    context 'with better performance' do
      before(:each) do
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:overallPerformanceScore).and_return({ position: 18, total_positions: 30 })
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:previousOverallPerformanceScore).and_return({ position: 20, total_positions: 30 })
      end

      it 'should indicate that the champion is doing better' do
        post action, params: params
        expect(speech).to eq 'Shyvana is doing better this patch in Jungle and is ranked 18th out of 30 with a 6.1/5.28/6.86 KDA, 51.87% win rate and a 0.02% ban rate in Gold division.'
      end
    end

    context 'with worse performance' do
      before(:each) do
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:overallPerformanceScore).and_return({ position: 20, total_positions: 30 })
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:previousOverallPerformanceScore).and_return({ position: 18, total_positions: 30 })
      end

      it 'should indicate that the champion is doing worse' do
        post action, params: params
        expect(speech).to eq 'Shyvana is doing worse this patch in Jungle and is ranked 20th out of 30 with a 6.1/5.28/6.86 KDA, 51.87% win rate and a 0.02% ban rate in Gold division.'
      end
    end

    context 'with equal performance' do
      before(:each) do
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:overallPerformanceScore).and_return({ position: 20, total_positions: 30 })
        allow_any_instance_of(RolePerformance).to receive(:position)
          .with(:previousOverallPerformanceScore).and_return({ position: 20, total_positions: 30 })
      end

      it 'should indicate that the champion has been introduced' do
        post action, params: params
        expect(speech).to eq 'Shyvana is doing the same this patch in Jungle and is ranked 20th out of 30 with a 6.1/5.28/6.86 KDA, 51.87% win rate and a 0.02% ban rate in Gold division.'
      end
    end

    context 'with a role specified' do
      it 'should return the role performance for the given role' do
        post action, params: params
        expect(speech). to eq 'Shyvana is doing worse this patch in Jungle and is ranked 8th out of 45 with a 6.1/5.28/6.86 KDA, 51.87% win rate and a 0.02% ban rate in Gold division.'
      end
    end

    context 'with no role specified' do
      before :each do
        champion_params[:role] = ''
      end

      it 'should determine the role based on the roles the champion plays' do
        post action, params: params
        expect(speech).to eq 'Shyvana is doing worse this patch in Jungle and is ranked 8th out of 45 with a 6.1/5.28/6.86 KDA, 51.87% win rate and a 0.02% ban rate in Gold division.'
      end
    end

    context 'error messages' do
      context 'does not play role' do
        before :each do
          champion_params[:name] = 'Jayce'
          champion_params[:role] = 'SUPPORT'
        end

        it 'should indicate that the champion does not play that role' do
          post action, params: params
          expect(speech).to eq 'I do not have any information on Jayce playing Support.'
        end
      end

      context 'plays multiple roles' do
        before :each do
          champion_params[:name] = 'Jayce'
          champion_params[:role] = ''
        end

        it 'should indicate that a role must be specified' do
          post action, params: params
          expect(response_body.dig(:data, :google, :expect_user_response)).to eq true
          expect(speech).to eq 'Jayce plays multiple roles, please specify a role.'
        end
      end
    end
  end

  describe 'POST ability' do
    let(:action) { :ability }
    let(:champion_params) do
      {
        name: 'Shyvana',
        ability_position: 'first'
      }
    end

    it 'should return the ability information for the specified champion' do
      post action, params: params
      expect(speech).to eq "Shyvana's first ability is called Twin Bite. Shyvana strikes twice on her next attack. Basic attacks reduce the cooldown of Twin Bite by 0.5 seconds. Dragon Form: Twin Bite cleaves all units in front Shyvana."
    end
  end

  describe 'POST cooldown' do
    let(:action) { :cooldown }
    let(:champion_params) do
      {
        name: 'Shyvana',
        ability_position: 'first',
        rank: '1'
      }
    end

    context 'with valid rank' do
      it 'should indicate the cooldown for the specified ability' do
        post action, params: params
        expect(speech).to eq "The cooldown of Shyvana's first ability, Twin Bite, is 9 seconds at rank 1."
      end
    end

    context 'with an invalid rank' do
      before :each do
        champion_params[:rank] = '6'
      end

      it 'should indicate the valid rank range' do
        post action, params: params
        expect(speech).to eq 'A valid ability rank is generally between 1 and 5.'
      end
    end
  end

  describe 'POST lore' do
    let(:action) { :lore }
    let(:champion_params) do
      { name: 'Shyvana' }
    end

    it 'should return the lore of the champion' do
      post action, params: params
      expect(speech).to start_with 'I will tell you about the history of Shyvana. My records are old so it may be incomplete: A half-breed born'
    end
  end

  describe 'POST title' do
    let(:action) { :title }
    let(:champion_params) do
      { name: 'Shyvana' }
    end

    it 'should return the champions title' do
      post action, params: params
      expect(speech).to eq 'Shyvana has the illustrious title of the Half-Dragon.'
    end
  end

  describe 'POST ally_tips' do
    let(:action) { :ally_tips }
    let(:champion_params) do
      { name: 'Shyvana' }
    end

    before :each do
      allow(controller).to receive(:champion_params).and_return(champion_params)
      champion = Champion.new(name: champion_params[:name])
      allow(Champion).to receive(:new).and_return(champion)
      allow(champion.allytips).to receive(:sample).and_return(
        champion.allytips.last
      )
    end

    it 'should provide tips for playing with the champion' do
      post action, params: params
      expect(speech).to eq "Here's something you should know about Shyvana: It can be valuable to purchase one of the items that can slow enemies: Frozen Mallet, Dead Man's Plate, or Entropy."
    end
  end

  describe 'POST enemy_tips' do
    let(:action) { :enemy_tips }
    let(:champion_params) do
      { name: 'Shyvana' }
    end

    before :each do
      allow(controller).to receive(:champion_params).and_return(champion_params)
      champion = Champion.new(name: champion_params[:name])
      allow(Champion).to receive(:new).and_return(champion)
      allow(champion.enemytips).to receive(:sample).and_return(
        champion.enemytips.last
      )
    end

    it 'should provide tips for playing against the champion' do
      post action, params: params
      expect(speech).to eq "I have seen Shyvana fall in battle before and this is what I would recommend: Shyvana's Fury Bar indicate her ultimate can be activated. Harassing her when she's low on Fury can be very effective."
    end
  end
end
