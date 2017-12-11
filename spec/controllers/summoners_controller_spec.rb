require 'rails_helper'
require 'spec_contexts.rb'

describe SummonersController, type: :controller do
  include_context 'spec setup'
  include_context 'determinate speech'

  before :each do
    allow(controller).to receive(:summoner_params).and_return(summoner_params)
  end

  describe 'POST champion_build' do
    let(:action) { :champion_build }
    let(:summoner_params) do
      {
        name: 'Hero man',
        champion: 'Shyvana',
        region: 'NA1',
        role: 'DUO_CARRY',
        list_order: 'highest',
        list_size: 2,
        metric: '',
        position_details: '',
        recency: ''
      }
    end

    before :each do
      @complete_build = [3089, 3087, 3085, 3083, 2303, 3512]
      @complete_build2 = [3089, 3089, 3085, 3083, 2303, 3512]
      @incomplete_build = [3089, 3086, 3085, 3083, 2303, 3512]
      @partial_build = [3083, 2303, 3512]
      match_data = [
        { match: { win: true }, build: @complete_build2, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @complete_build2, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @complete_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @complete_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @complete_build.reverse, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, build: @incomplete_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, build: @incomplete_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @partial_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @partial_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @partial_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, build: @partial_build, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
      ]
      @matches = create_list(:match, match_data.length)
      summoner = create(:summoner, name: 'Hero man')

      @matches.each_with_index do |match, i|
        summoner_performance = match.summoner_performances.first
        opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
        winning_team = match_data[i][:match][:win] ? summoner_performance.team : opposing_team
        match.update!(winning_team: winning_team)
        summoner_performance.update!(match_data[i][:summoner_performance].merge({ summoner_id: summoner.id }))
        match_data[i][:build].each_with_index do |item_id, index|
          summoner_performance.update_attribute("item#{index}_id", item_id)
        end
      end
    end

    context 'with no role specified' do
      before :each do
        summoner_params[:role] = ''
      end

      context 'with a single role played' do
        it 'should determine builds for the single role' do
          post action, params: params
          expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
        end
      end

      context 'with multiple roles played' do
        before :each do
          @matches.first.summoner_performances.first.update_attribute(:role, 'JUNGLE')
        end

        it 'should indicate that the summoner has played the champion in multiple roles' do
          post action, params: params
          expect(speech).to eq "Hero man has played Shyvana eleven times this season across Adc and Jungle. Which role do you want to know about?"
        end
      end
    end

    context 'when the champion has not been played recently' do
      before :each do
        summoner_params[:recency] = :recently
        @matches.each do |match|
          match.summoner_performances.first.update_attribute(:created_at, 1.year.ago)
        end
      end

      it 'should indicate that the summoner has not played the champion recently' do
        post action, params: params
        expect(speech).to eq "Hero man has not played any games recently as Shyvana Adc."
      end
    end

    context 'when the champion has not been played this season' do
      before :each do
        @matches.each do |match|
          match.summoner_performances.first.update_attribute(:champion_id, 101)
        end
      end

      it 'should indicate that the summoner has not played the champion this season' do
        post action, params: params
        expect(speech).to eq "Hero man has not played any games this season as Shyvana Adc."
      end
    end

    context 'without recency specified' do
      it 'should determine builds from all games' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with recency specified' do
      before :each do
        summoner_params[:recency] = :recently
        @matches.first(4).each do |match|
          match.summoner_performances.first.update!(created_at: 1.year.ago)
        end
      end

      it 'should determine builds from games in the past month' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc seven times recently and the summoner's highest win rate build is Zz'Rot Portal, Eye of the Equinox, Warmog's Armor, Runaan's Hurricane, Statikk Shiv, and Rabadon's Deathcap."
      end
    end

    context 'without a metric or position details specified' do
      it 'should use winrate as the default metric' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a position details specified' do
      before :each do
        summoner_params[:position_details] = :penta_kills
        @matches.first.summoner_performances.first.update!(penta_kills: 100000000)
      end

      it 'should use the position details to determine the build' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest penta kills build is two Rabadon's Deathcaps, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a winrate metric specified' do
      before :each do
        summoner_params[:metric] = :winrate
      end

      it 'should use winrate as the build metric' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a KDA metric specified' do
      before :each do
        summoner_params[:metric] = :KDA
        @matches.first.summoner_performances.first.update!(kills: 100000000)
      end

      it 'should use KDA as the build metric' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest KDA build is two Rabadon's Deathcaps, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a count metric specified' do
      before :each do
        summoner_params[:metric] = :count
      end

      it 'should use the frequency of the build as the metric' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest games played build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with only partial builds' do
      before :each do
        @matches.each do |match|
          match.summoner_performances.first.update_attribute(:item0_id, nil)
        end
      end

      it 'should indicate the summoner has never completed a build' do
        post action, params: params
        expect(speech).to eq 'Hero man does not have any complete builds playing Shyvana Adc this season.'
      end
    end

    context 'with multiple orders of the same build' do
      before :each do
        build = @complete_build.reverse
        summoner_performance = @matches[2].summoner_performances.first
        build.each_with_index do |item_id, index|
          summoner_performance.update_attribute("item#{index}_id", item_id)
        end
      end

      it 'should use the order that appears most frequently' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times this season and the summoner's highest win rate build is Zz'Rot Portal, Eye of the Equinox, Warmog's Armor, Runaan's Hurricane, Statikk Shiv, and Rabadon's Deathcap."
      end
    end
  end

  describe 'POST performance_summary' do
    let(:action) { :performance_summary }
    let(:external_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][action]
    end
    let(:summoner_params) do
      { name: 'Wingilote', region: 'NA1', queue: 'RANKED_SOLO_5x5' }
    end

    before :each do
      summoner = create(:summoner, name: 'Wingilote')
      allow(RiotApi::RiotApi).to receive(:fetch_response).and_return(
        external_response
      )
      Cache.set_summoner_rank(summoner.summoner_id, nil)
    end

    context 'when cached' do
      it 'should not make an API request' do
        post action, params: params
        post action, params: params
        expect(RiotApi::RiotApi).to have_received(:fetch_response).once
      end
    end

    context 'with no summoner information' do
      before :each do
        summoner_params[:name] = 'inactive player'
      end

      it 'should indicate that the summoner does not play in that queue' do
        post action, params: params
        expect(speech).to eq 'inactive player is not an active player in ranked this season.'
      end
    end

    it 'should return the summoner information' do
      post action, params: params
      expect(speech).to eq 'Wingilote is ranked Gold V with 84 LP in Solo Queue. The summoner currently has a 50.16% win rate.'
    end

    it 'should vary the information by queue' do
      summoner_params[:queue] = 'RANKED_FLEX_SR'
      post action, params: params
      expect(speech).to eq 'Wingilote is ranked Bronze I with 28 LP in Flex Queue. The summoner currently has a 60.78% win rate.'
    end
  end

  describe 'POST champion_matchup_ranking' do
    let(:action) { :champion_matchup_ranking }
    let(:summoner_params) do
      {
        name: 'Hero man',
        champion: 'Shyvana',
        region: 'NA1',
        role: 'MIDDLE',
        list_order: 'highest',
        list_position: 1,
        list_size: 2,
        metric: '',
        position_details: '',
        recency: ''
      }
    end

    before :each do
      @matches = create_list(:match, 6)
      match_data = [
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' }, opponent: { champion_id: 40 } },
        { match: { win: false }, summoner_performance: { champion_id: 102, role: 'MIDDLE' }, opponent: { champion_id: 50 } },
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'MIDDLE' }, opponent: { champion_id: 60 } },
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, opponent: { champion_id: 40 } },
        { match: { win: false }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, opponent: { champion_id: 50 } },
        { match: { win: false }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, opponent: { champion_id: 60 } },
      ]
      summoner = create(:summoner, name: 'Hero man')
      @matches.each_with_index do |match, i|
        summoner_performance = match.summoner_performances.first
        opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
        if match_data[i][:match][:win]
          match.update!(winning_team: summoner_performance.team)
        else
          match.update!(winning_team: opposing_team)
        end
        summoner_performance.update!(
          match_data[i][:summoner_performance].merge({ summoner_id: summoner.id })
        )
        opposing_team.summoner_performances.first
          .update!(match_data[i][:opponent].merge({ role: match_data[i][:summoner_performance][:role] }))
      end
    end

    context 'with no opponents' do
      before :each do
        @matches.each do |match|
          summoner_performance = match.summoner_performances.first
          opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          opposing_team.summoner_performances.first.update_attribute(:role, '')
        end
      end

      context 'with recency' do
        before :each do
          summoner_params[:recency] = :recently
        end

        it 'should indicate that there are no recent opponents' do
          post action, params: params
          expect(speech).to eq 'I could not find any opponents for Hero man playing Shyvana Middle recently.'
        end
      end

      context 'without recency' do
        it 'should indicate that there have been no opponents this season' do
          post action, params: params
          expect(speech).to eq 'I could not find any opponents for Hero man playing Shyvana Middle this season.'
        end
      end
    end

    context 'with both a metric and position details specified' do
      before :each do
        summoner_params[:metric] = :count
        summoner_params[:position_details] = 'kills'
      end

      it 'should sort the matchup rankings by metric' do
        post action, params: params
        expect(speech).to eq 'The champions with the highest games played against Hero man playing Shyvana Middle are Elise and Swain.'
      end
    end

    context 'with only a metric specified' do
      context 'with a count metric specified' do
        before :each do
          summoner_params[:metric] = :count
        end

        it 'should sort the matchup rankings by metric' do
          post action, params: params
          expect(speech).to eq 'The champions with the highest games played against Hero man playing Shyvana Middle are Elise and Swain.'
        end
      end

      context 'with a KDA metric specified' do
        before :each do
          summoner_params[:metric] = :KDA
          SummonerPerformance.find_by(champion_id: 50, role: 'MIDDLE').update!(kills: 100000)
        end

        it 'should sort the matchup rankings by KDA' do
          post action, params: params
          expect(speech).to eq 'The champions with the highest KDA against Hero man playing Shyvana Middle are Swain and Elise.'
        end
      end

      context 'with a winrate metric specified' do
        before :each do
          summoner_params[:metric] = :winrate
        end

        it 'should sort the matchup rankings by winrate' do
          post action, params: params
          expect(speech).to eq 'The champions with the highest win rate against Hero man playing Shyvana Middle are Swain and Elise.'
        end
      end
    end

    context 'with only a position details specified' do
      before :each do
        summoner_params[:position_details] = :penta_kills
        @matches.first(2).each do |match|
          summoner_performance = match.summoner_performances.first
          opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          opposing_team.summoner_performances.first.update_attribute(:penta_kills, 100000)
        end
      end

      it 'should sort the matchup rankings by the specified position' do
        post action, params: params
        expect(speech).to eq 'The champions with the highest penta kills against Hero man playing Shyvana Middle are Swain and Elise.'
      end
    end

    context 'with no results returned' do
      context 'with no position offset' do
        before :each do
          summoner_params[:name] = 'inactive player'
        end

        it 'should indicate that the player is not active this season' do
          post action, params: params
          expect(speech).to eq 'inactive player is not an active player in ranked this season.'
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 5
        end

        context 'with complete results' do
          before :each do
            summoner_params[:list_size] = 0
          end

          it 'should indicate that no champions were requested' do
            post action, params: params
            expect(speech).to eq 'No champions were requested.'
          end
        end

        context 'with incomplete results' do
          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should indicate that the summoner has not played against that many champions recently' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against two champions playing as Shyvana Middle recently.'
            end
          end

          context 'without recency' do
            it 'should indicate that the summoner has not played against that many champions' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against two champions playing as Shyvana Middle so far this season.'
            end
          end
        end
      end
    end

    context 'with a single result returned' do
      context 'with no position offset' do
        context 'with complete results' do
          before :each do
            summoner_params[:list_size] = 1
          end

          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the single champion indicating recency' do
              post action, params: params
              expect(speech).to eq 'The champion with the highest win rate playing against Hero man recently as Shyvana Middle is Swain.'
            end
          end

          context 'without recency' do
            it 'should return the single champion' do
              post action, params: params
              expect(speech).to eq 'The champion with the highest win rate playing against Hero man as Shyvana Middle is Swain.'
            end
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:role] = 'DUO_CARRY'
          end

          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the single champion, indicating the list is incomplete' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against one champion recently as Shyvana Adc. The champion with the highest win rate playing against Hero man as Shyvana Adc is Janna.'
            end
          end

          context 'without recency' do
            it 'should return the single champion, indicating the list is incomplete' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against one champion so far this season as Shyvana Adc. The champion with the highest win rate playing against Hero man as Shyvana Adc is Janna.'
            end
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
        end

        context 'with complete results' do
          before :each do
            summoner_params[:list_size] = 1
          end

          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the single champion indicating recency' do
              post action, params: params
              expect(speech).to eq 'The champion with the second highest win rate playing against Hero man recently as Shyvana Middle is Elise.'
            end
          end

          context 'without recency' do
            it 'should return the single champion' do
              post action, params: params
              expect(speech).to eq 'The champion with the second highest win rate playing against Hero man as Shyvana Middle is Elise.'
            end
          end
        end

        context 'with incomplete results' do
          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the single champion and indicate the results are not complete recently' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against two different champions recently as Shyvana Middle. The champion with the second highest win rate playing against Hero man as Shyvana Middle is Elise.'
            end
          end

          context 'without recency' do
            it 'should return the single champion and indicate the results are not complete' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against two different champions so far this season as Shyvana Middle. The champion with the second highest win rate playing against Hero man as Shyvana Middle is Elise.'
            end
          end
        end
      end
    end

    context 'with multiple results returned' do
      context 'with no position offset' do
        context 'with complete results' do
          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the list of champions indicating recency' do
              post action, params: params
              expect(speech).to eq 'The champions with the highest win rate against Hero man recently playing Shyvana Middle are Swain and Elise.'
            end
          end

          context 'without recency' do
            it 'should return the list of champions' do
              post action, params: params
              expect(speech).to eq 'The champions with the highest win rate against Hero man playing Shyvana Middle are Swain and Elise.'
            end
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 4
          end

          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the list of champions indicating it is incomplete recently' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against two different champions recently as Shyvana Middle. The champions with the highest win rate playing against Hero man Middle are Swain and Elise.'
            end
          end

          context 'without recency' do
            it 'should return the list of champions indicating it is incomplete' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against two different champions so far this season as Shyvana Middle. The champions with the highest win rate playing against Hero man Middle are Swain and Elise.'
            end
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
          summoner_params[:role] = 'JUNGLE'
        end

        context 'with complete results' do
          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the complete list of champions' do
              post action, params: params
              expect(speech).to eq 'The second through third champions with the highest win rate against Hero man recently playing Shyvana Jungle are Swain and Janna.'
            end
          end

          context 'without recency' do
            it 'should return the complete list of champions' do
              post action, params: params
              expect(speech).to eq 'The second through third champions with the highest win rate against Hero man playing Shyvana Jungle are Swain and Janna.'
            end
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 5
          end

          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should return the list of champions, indicating that it is incomplete recently' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against three different champions recently as Shyvana Jungle. The second through third champions with the highest win rate against Hero man playing as Shyvana Jungle are Swain and Janna.'
            end
          end

          context 'without recency' do
            it 'should return the list of champions, indicating that it is incomplete' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played against three different champions so far this season as Shyvana Jungle. The second through third champions with the highest win rate against Hero man playing as Shyvana Jungle are Swain and Janna.'
            end
          end
        end
      end
    end
  end

  describe 'POST champion_performance_ranking' do
    let(:action) { :champion_performance_ranking }
    let(:summoner_params) do
      {
        name: 'Hero man',
        region: 'NA1',
        role: '',
        list_order: 'highest',
        list_position: 1,
        list_size: 2,
        metric: '',
        position_details: '',
        recency: ''
      }
    end

    before :each do
      matches = create_list(:match, 5)
      match_data = [
        { match: { win: true }, summoner_performance: { champion_id: 18, role: 'DUO_CARRY' } },
        { match: { win: false }, summoner_performance: { champion_id: 18, role: 'MIDDLE' } },
        { match: { win: true }, summoner_performance: { champion_id: 20, role: 'MIDDLE' } },
        { match: { win: true }, summoner_performance: { champion_id: 20, role: 'JUNGLE' } },
        { match: { win: false }, summoner_performance: { champion_id: 18, role: 'JUNGLE' } },
      ]
      summoner = create(:summoner, name: 'Hero man')
      matches.each_with_index do |match, i|
        summoner_performance = match.summoner_performances.first
        if match_data[i][:match][:win]
          match.update!(winning_team: summoner_performance.team)
        else
          match.update!(winning_team: summoner_performance.team == match.team1 ? match.team2 : match.team1)
        end
        summoner_performance.update!(
          match_data[i][:summoner_performance].merge({ summoner_id: summoner.id })
        )
      end
    end

    context 'with a metric and position details specified' do
      before :each do
        summoner_params[:metric] = :count
        summoner_params[:position_details] = 'kills'
      end

      it 'should sort the ranking by the metric' do
        post action, params: params
        expect(speech).to eq "The champions played by Hero man with the summoner's highest games played are Tristana and Nunu."
      end
    end

    context 'with only a metric specified' do
      context 'with a count metric given' do
        before :each do
          summoner_params[:metric] = :count
        end

        it 'should rank by games played' do
          post action, params: params
          expect(speech).to eq "The champions played by Hero man with the summoner's highest games played are Tristana and Nunu."
        end
      end

      context 'with a KDA metric given' do
        before :each do
          Match.last.summoner_performances.first.update!(kills: 10000)
          summoner_params[:metric] = :KDA
        end

        it 'should rank by average KDA' do
          post action, params: params
          expect(speech).to eq "The champions played by Hero man with the summoner's highest KDA are Tristana and Nunu."
        end
      end

      context 'with a winrate metric given' do
        before :each do
          summoner_params[:metric] = :winrate
        end

        it 'should rank by overall winrate' do
          post action, params: params
          expect(speech).to eq "The champions played by Hero man with the summoner's highest win rate are Nunu and Tristana."
        end
      end
    end

    context 'with only a position details specified' do
      before :each do
        summoner_params[:position_details] = :wards_placed
        Match.last.summoner_performances.first.update!(wards_placed: 10000)
      end

      it 'should rank by the position details' do
        post action, params: params
        expect(speech).to eq "The champions played by Hero man with the summoner's highest wards placed are Tristana and Nunu."
      end
    end

    context 'with no champions returned' do
      context 'with no position offset' do
        context 'with complete results' do
          before :each do
            summoner_params[:list_size] = 0
          end

          it 'should indicate that no champions were requested' do
            post action, params: params
            expect(speech).to eq 'No champions were requested.'
          end
        end

        context 'with incomplete results' do
          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'TOP'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate that the summoner has not played in that role recently' do
                post action, params: params
                expect(speech).to eq 'Hero man has not played any games recently as Top in ranked solo queue.'
              end
            end

            context 'without recency' do
              it 'should indicate that the summoner has not played in that role' do
                post action, params: params
                expect(speech).to eq 'Hero man has not played any games this season as Top in ranked solo queue.'
              end
            end
          end

          context 'with no role specified' do
            before :each do
              summoner_params[:name] = 'inactive player'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate that the summoner has not played recently.' do
                post action, params: params
                expect(speech).to eq 'inactive player is not an active player in ranked recently.'
              end
            end

            context 'without recency' do
              it 'should indicate that the summoner has not played this season.' do
                post action, params: params
                expect(speech).to eq 'inactive player is not an active player in ranked this season.'
              end
            end
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 100
        end

        context 'with complete results' do
          before :each do
            summoner_params[:list_size] = 0
          end

          it 'should indicate that no champions were requested' do
            post action, params: params
            expect(speech).to eq 'No champions were requested.'
          end
        end

        context 'with incomplete results' do
          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'JUNGLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate that the summoner has not played offset champions recently in that role' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions as Jungle recently.'
              end
            end

            context 'without recency' do
              it 'should indicate that the summoner has not played offset champions this season in that role' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions as Jungle so far this season.'
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate that the summoner has not played offset champions recently' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions recently.'
              end
            end

            context 'without recency' do
              it 'should indicate that the summoner has not played offset champions this season' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions so far this season.'
              end
            end
          end
        end
      end
    end

    context 'with a single champion returned' do
      before :each do
        summoner_params[:list_size] = 1
      end

      context 'with no position offset' do
        context 'with a complete response' do
          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'MIDDLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return the single highest ranking for that role recently' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man recently with the highest win rate in Middle is Nunu.'
              end
            end

            context 'without recency' do
              it 'should return the single highest ranking for that role' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man with the highest win rate in Middle is Nunu.'
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return the single highest ranking for any role recently' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man recently with the highest win rate is Nunu.'
              end
            end

            context 'without recency' do
              it 'should return the single highest ranking for any role' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man with the highest win rate is Nunu.'
              end
            end
          end
        end

        context 'with an incomplete response' do
          before :each do
            summoner_params[:name] = 'inactive player'
          end

          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'Top'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate that the player is inactive recently' do
                post action, params: params
                expect(speech).to eq 'inactive player is not an active player in ranked recently.'
              end
            end

            context 'without recency' do
              it 'should indicate that the player is inactive this season' do
                post action, params: params
                expect(speech).to eq 'inactive player is not an active player in ranked this season.'
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate that the player is inactive recently' do
                post action, params: params
                expect(speech).to eq 'inactive player is not an active player in ranked recently.'
              end
            end

            context 'without recency' do
              it 'should indicate that the player is inactive this season' do
                post action, params: params
                expect(speech).to eq 'inactive player is not an active player in ranked this season.'
              end
            end
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
        end

        context 'with a complete response' do
          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'MIDDLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return the offset highest champion for that role recently' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man recently with the second highest win rate in Middle is Tristana.'
              end
            end

            context 'with no recency' do
              it 'should return the offset highest champion for that role' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man with the second highest win rate in Middle is Tristana.'
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return the offset highest champion for any role recently' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man recently with the second highest win rate is Tristana.'
              end
            end

            context 'without recency' do
              it 'should return the offset highest champion for any role' do
                post action, params: params
                expect(speech).to eq 'The champion played by Hero man with the second highest win rate is Tristana.'
              end
            end
          end
        end

        context 'with an incomplete response' do
          before :each do
            summoner_params[:list_size] = 3
          end

          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'MIDDLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate the results are incomplete and return the one champion for that role recently' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions recently as Middle. The champion played by Hero man with the second highest win rate as Middle is Tristana.'
              end
            end

            context 'without recency' do
              it 'should indicate the results are incomplete and return the one champion for that role' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions so far this season as Middle. The champion played by Hero man with the second highest win rate as Middle is Tristana.'
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should indicate the results are incomplete and return the one recent champion' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions recently. The champion played by Hero man with the second highest win rate is Tristana.'
              end
            end

            context 'without recency' do
              it 'should indicate the results are incomplete and return the one champion' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played two champions so far this season. The champion played by Hero man with the second highest win rate is Tristana.'
              end
            end
          end
        end
      end
    end

    context 'with multiple champions returned' do
      context 'with no position offset' do
        context 'with a complete response' do
          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'MIDDLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should provide rankings for the champions in that role recently' do
                post action, params: params
                expect(speech).to eq "The champions played by Hero man recently with the summoner's highest win rate in Middle are Nunu and Tristana."
              end
            end

            context 'without recency' do
              it 'should provide rankings for the champions in that role' do
                post action, params: params
                expect(speech).to eq "The champions played by Hero man with the summoner's highest win rate in Middle are Nunu and Tristana."
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should provide rankings for the champions in any role recently' do
                post action, params: params
                expect(speech).to eq "The champions played by Hero man recently with the summoner's highest win rate are Nunu and Tristana."
              end
            end

            context 'without recency' do
              it 'should provide rankings for the champions in any role' do
                post action, params: params
                expect(speech).to eq "The champions played by Hero man with the summoner's highest win rate are Nunu and Tristana."
              end
            end
          end
        end

        context 'with an incomplete response' do
          before :each do
            summoner_params[:list_size] = 3
          end

          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'MIDDLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return an incomplete ranking of champions in that role recently' do
                post action, params: params
                expect(speech).to eq "Hero man has only played two champions recently as Middle. The champions played by Hero man with the summoner's highest win rate as Middle are Nunu and Tristana."
              end
            end

            context 'without recency' do
              it 'should return an incomplete ranking of champions in that role' do
                post action, params: params
                expect(speech).to eq "Hero man has only played two champions so far this season as Middle. The champions played by Hero man with the summoner's highest win rate as Middle are Nunu and Tristana."
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return an incomplete ranking of champions in any role recently' do
                post action, params: params
                expect(speech).to eq "Hero man has only played two champions recently. The champions played by Hero man with the summoner's highest win rate are Nunu and Tristana."
              end
            end

            context 'without recency' do
              it 'should return an incomplete ranking of champions in any role' do
                post action, params: params
                expect(speech).to eq "Hero man has only played two champions so far this season. The champions played by Hero man with the summoner's highest win rate are Nunu and Tristana."
              end
            end
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
          Match.last.summoner_performances.first.update!(champion_id: 30, role: 'MIDDLE')
        end

        context 'with complete rankings' do
          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'MIDDLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return a complete ranking with champions from that role recently' do
                post action, params: params
                expect(speech).to eq 'The second through third champions played by Hero man recently with the highest win rate in Middle are Karthus and Tristana.'
              end
            end

            context 'without recency' do
              it 'should return a complete ranking with champions from that role' do
                post action, params: params
                expect(speech).to eq 'The second through third champions played by Hero man with the highest win rate in Middle are Karthus and Tristana.'
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return a complete ranking with recent champions from all roles' do
                post action, params: params
                expect(speech).to eq 'The second through third champions played by Hero man recently with the highest win rate are Tristana and Karthus.'
              end
            end

            context 'without recency' do
              it 'should return a complete ranking with champions from all roles' do
                post action, params: params
                expect(speech).to eq 'The second through third champions played by Hero man with the highest win rate are Tristana and Karthus.'
              end
            end
          end
        end

        context 'with incomplete rankings' do
          before :each do
            summoner_params[:list_size] = 3
          end

          context 'with a role specified' do
            before :each do
              summoner_params[:role] = 'MIDDLE'
            end

            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return incomplete rankings for that role recently' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played three champions recently as Middle. The second through third champions played by Hero man with the highest win rate as Middle are Karthus and Tristana.'
              end
            end

            context 'without recency' do
              it 'should return incomplete rankings for that role' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played three champions so far this season as Middle. The second through third champions played by Hero man with the highest win rate as Middle are Karthus and Tristana.'
              end
            end
          end

          context 'with no role specified' do
            context 'with recency' do
              before :each do
                summoner_params[:recency] = :recently
              end

              it 'should return incomplete rankings across all roles recently' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played three champions recently. The second through third champions played by Hero man with the highest win rate are Tristana and Karthus.'
              end
            end

            context 'without recency' do
              it 'should return incomplete rankings across all roles' do
                post action, params: params
                expect(speech).to eq 'Hero man has only played three champions so far this season. The second through third champions played by Hero man with the highest win rate are Tristana and Karthus.'
              end
            end
          end
        end
      end
    end
  end

  describe 'POST champion_performance_summary' do
    let(:action) { :champion_performance_summary }
    let(:summoner_params) do
      {
        name: 'Hero man',
        region: 'NA1',
        champion: 'Tristana',
        role: 'DUO_CARRY',
        recency: ''
      }
    end

    before :each do
      @match1 = create(:match)
      @match2 = create(:match)
      summoner_performance = @match1.summoner_performances.first
      summoner_performance.update!(champion_id: 18, role: 'DUO_CARRY')
      summoner_performance.summoner.update!(name: 'Hero man')
      @match2.summoner_performances.first.update(
        champion_id: 18,
        role: 'DUO_CARRY',
        summoner: summoner_performance.summoner
      )
    end

    context 'with no games played as that champion' do
      context 'with a role specified' do
        before :each do
          summoner_params[:role] = 'TOP'
        end

        context 'with recency' do
          before :each do
            summoner_params[:recency] = :recently
          end

          it 'should indicate that the summoner has not played the champion in that role recently' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games recently as Tristana Top.'
          end
        end

        context 'without recency' do
          it 'should indicate that the summoner has not played the champion in that role' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games this season as Tristana Top.'
          end
        end
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
          summoner_params[:champion] = 'Zed'
        end

        context 'with recency' do
          before :each do
            summoner_params[:recency] = :recently
          end

          it 'should indicate that the summoner has not played the champion recently' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games recently as Zed.'
          end
        end

        context 'without recency' do
          it 'should indicate that the summoner has not played the champion this season' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games this season as Zed.'
          end
        end
      end
    end

    context 'with games played as that champion' do
      context 'with a role specified' do
        context 'with recency' do
          before :each do
            summoner_params[:recency] = :recently
          end

          it 'should determine the win rate and KDA for the specified role recently' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana Adc two times recently with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
          end
        end

        context 'without recency' do
          it 'should determine the win rate and KDA for the specified role' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana Adc two times this season with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
          end
        end
      end

      context 'with no role specified' do
        let(:summoner_params) do
          { name: 'Hero man', region: 'NA1', champion: 'Tristana', role: '', recency: '' }
        end

        context 'with one role' do
          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should determine the win rate and KDA for the one role recently' do
              post action, params: params
              expect(speech).to eq 'Hero man has played Tristana Adc two times recently with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
            end
          end

          context 'without recency' do
            it 'should determine the win rate and KDA for the one role' do
              post action, params: params
              expect(speech).to eq 'Hero man has played Tristana Adc two times this season with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
            end
          end
        end

        context 'with multiple roles' do
          before :each do
            @match2.summoner_performances.first.update(role: 'DUO_SUPPORT')
          end

          it 'should prompt to specify a role' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana two times this season across Adc and Support. Which role do you want to know about?'
          end
        end
      end
    end
  end

  describe 'POST champion_performance_position' do
    let(:action) { :champion_performance_position }
    let(:summoner_params) do
      {
        name: 'Hero man',
        champion: 'Tristana',
        role: 'DUO_CARRY',
        position_details: 'kills',
        region: 'NA1',
        recency: ''
      }
    end

    before :each do
      @match1 = create(:match)
      @match2 = create(:match)
      summoner_performance = @match1.summoner_performances.first
      summoner_performance.update!(champion_id: 18, role: 'DUO_CARRY')
      summoner_performance.summoner.update!(name: 'Hero man')
      @match2.summoner_performances.first.update(
        champion_id: 18,
        role: 'DUO_CARRY',
        summoner: summoner_performance.summoner
      )
    end

    context 'with no games played as that champion' do
      context 'with a role specified' do
        before :each do
          summoner_params[:role] = 'TOP'
        end

        context 'with recency' do
          before :each do
            summoner_params[:recency] = :recently
          end

          it 'should indicate that the summoner has not played the champion in that role recently' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games recently as Tristana Top.'
          end
        end

        context 'without recency' do
          it 'should indicate that the summoner has not played the champion in that role' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games this season as Tristana Top.'
          end
        end
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
          summoner_params[:champion] = 'Zed'
        end

        context 'with recency' do
          before :each do
            summoner_params[:recency] = :recently
          end

          it 'should indicate that the summoner has not played the champion this season recently' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games recently as Zed.'
          end
        end

        context 'without recency' do
          it 'should indicate that the summoner has not played the champion this season' do
            post action, params: params
            expect(speech).to eq 'Hero man has not played any games this season as Zed.'
          end
        end
      end
    end

    context 'with games played as that champion' do
      context 'with a role specified' do
        context 'with recency' do
          before :each do
            summoner_params[:recency] = :recently
          end

          it 'should determine the position performance for that role recently' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana Adc two times recently and averages 2.0 kills.'
          end
        end

        context 'without recency' do
          it 'should determine the position performance for that role' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana Adc two times this season and averages 2.0 kills.'
          end
        end
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
        end

        context 'with one role' do
          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should determine the position performance for the one role recently' do
              post action, params: params
              expect(speech).to eq 'Hero man has played Tristana Adc two times recently and averages 2.0 kills.'
            end
          end

          context 'without recency' do
            it 'should determine the position performance for the one role' do
              post action, params: params
              expect(speech).to eq 'Hero man has played Tristana Adc two times this season and averages 2.0 kills.'
            end
          end
        end

        context 'with multiple roles' do
          before :each do
            @match2.summoner_performances.first.update(role: 'DUO_SUPPORT')
          end

          context 'with recency' do
            before :each do
              summoner_params[:recency] = :recently
            end

            it 'should prompt to specify a role recently' do
              post action, params: params
              expect(speech).to eq 'Hero man has played Tristana two times recently this season across Adc and Support. Which role do you want to know about?'
            end
          end

          context 'without recency' do
            it 'should prompt to specify a role' do
              post action, params: params
              expect(speech).to eq 'Hero man has played Tristana two times this season across Adc and Support. Which role do you want to know about?'
            end
          end
        end
      end
    end
  end
end
