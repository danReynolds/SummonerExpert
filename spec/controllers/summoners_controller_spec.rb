require 'rails_helper'
require 'spec_contexts.rb'

describe SummonersController, type: :controller do
  include_context 'spec setup'
  include_context 'determinate speech'

  before :each do
    allow(controller).to receive(:summoner_params).and_return(summoner_params)
    Timecop.freeze(Time.new(2018, 2, 7))
    @today = "#{Time.now.strftime("%Y-%m-%d")}/#{(Time.now + 1.day).strftime("%Y-%m-%d")}"
  end

  describe 'POST current_match' do
    let(:action) { :current_match }
    let(:summoner_params) do
      {
        name: 'wingilote',
        region: 'NA1',
      }
    end
    let(:current_match_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][action]
    end
    let(:summoner_queue_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][:summoner_matchups]
    end

    before :each do
      allow(RiotApi::RiotApi).to receive(:get_current_match).and_return(
        current_match_response
      )
      allow(RiotApi::RiotApi).to receive(:fetch_response).and_return(
        summoner_queue_response
      )
      @summoner = create(:summoner, name: 'wingilote')
      @summoner2 = create(:summoner, name: 'endless white')
      @champion = Champion.new(name: 'Miss Fortune')
      @champion2 = Champion.new(name: 'Caitlyn')

      @matches = create_list(:match, 5)
      match_data = [
        { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
      ]

      @matches.each_with_index do |match, i|
        summoner_performance = match.summoner_performances.first
        @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
        if match_data[i][:match][:win]
          match.update!(winning_team: summoner_performance.team)
        else
          match.update!(winning_team: @opposing_team)
        end
        summoner_performance.update!(match_data[i][:summoner_performance])
        @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
      end
    end

    context 'with the summoner in game' do
      it "should determine the performance ratings for the summoner's lane" do
        post action, params: params
        expect(speech).to eq 'I would give wingilote playing Miss Fortune a performance rating of 93% for this matchup compared to endless white as Caitlyn who I would rate around 39%. My best guess is that wingilote will perform well this time. Ask me why if you want to know more.'
      end
    end

    context 'with the summoner not in game' do
      before :each do
        allow(RiotApi::RiotApi).to receive(:get_current_match).and_return(nil)
      end

      it 'should indicate that the summoner is not in game' do
        post action, params: params
        expect(speech).to eq 'I do not believe wingilote is in a game at the moment.'
      end
    end
  end

  describe 'POST current_match_reasons' do
    let(:action) { :current_match_reasons }
    let(:summoner_params) do
      {
        name: 'wingilote',
        region: 'NA1',
      }
    end

    before :each do
      @summoner = create(:summoner, name: 'wingilote')
      allow(Cache).to receive(:get_current_match_rating).and_return(
        {:own_performance=>
          {:rating=>0.88868929542452,
           :reasons=>
            [{:name=>:CHAMPION_WIN_RATE, :args=>{:own=>80.0, :opposing=>53.91}},
              {:name=>:CHAMPION_KDA, :args=>{:own=>3.0, :opposing=>2.6886223520440473}},
              {:name=>:CHAMPION_CS, :args=>{:own=>250.0, :opposing=>187.89939358402643}},
              {:name=>:CHAMPION_GOLD, :args=>{:own=>25000.0, :opposing=>12775.482370731557}},
              {:name=>:STREAK, :args=>{:streak_type=>:losing, :streak_length=>1}},
              {:name=>:MATCHUP_WIN_RATE, :args=>{:own=>80.0, :opposing=>54.07}},
              {:name=>:MATCHUP_KDA, :args=>{:own=>3.0, :opposing=>2.802169602239589}},
              {:name=>:MATCHUP_CS, :args=>{:own=>250.0, :opposing=>188.51400651465798}},
              {:name=>:MATCHUP_GOLD, :args=>{:own=>25000.0, :opposing=>12669.788664495114}}]},
         :opposing_performance=>
          {:rating=>0.6112550564363732,
           :reasons=>
            [{:name=>:CHAMPION_WIN_RATE, :args=>{:own=>20.0, :opposing=>48.87}},
              {:name=>:CHAMPION_KDA, :args=>{:own=>3.0, :opposing=>2.341214808363023}},
              {:name=>:CHAMPION_CS, :args=>{:own=>250.0, :opposing=>198.90990635925058}},
              {:name=>:CHAMPION_GOLD, :args=>{:own=>25000.0, :opposing=>12531.021625685155}},
              {:name=>:STREAK, :args=>{:streak_type=>:winning, :streak_length=>1}},
              {:name=>:MATCHUP_WIN_RATE, :args=>{:own=>20.0, :opposing=>45.93}},
              {:name=>:MATCHUP_KDA, :args=>{:own=>3.0, :opposing=>2.235953089445125}},
              {:name=>:MATCHUP_CS, :args=>{:own=>250.0, :opposing=>199.25550488599347}},
              {:name=>:MATCHUP_GOLD, :args=>{:own=>25000.0, :opposing=>12514.795960912052}}]},
         :summoner=>"wingilote",
         :champion=>"Miss Fortune",
         :opposing_champion=>"Caitlyn",
         :opposing_summoner=>"endless white",
         :role=>"DUO_CARRY"}
      )
    end

    it 'should provide the reasons from the cached current match rating' do
      post action, params: params
      expect(response_body).to eq ({"speech"=>"",
       "messages"=>
        [{"type"=>0, "speech"=>"Here are all the factors I considered for wingilote:"},
         {"type"=>0, "speech"=>"wingilote has a 80.0% win rate overall playing Miss Fortune Adc vs the current average of 53.91%."},
         {"type"=>0, "speech"=>"wingilote has a 3.0 KDA overall playing Miss Fortune Adc vs the current average of 2.6886223520440473."},
         {"type"=>0, "speech"=>"wingilote has 250.0 CS overall playing Miss Fortune Adc vs the current average of 187.89939358402643."},
         {"type"=>0, "speech"=>"wingilote earns an average of 25000.0 gold overall playing Miss Fortune Adc vs the current average of 12775.482370731557."},
         {"type"=>0, "speech"=>"wingilote is on a 1 game losing streak."},
         {"type"=>0, "speech"=>"wingilote has a 80.0% win rate playing Miss Fortune Adc in this matchup vs the current average of 54.07%."},
         {"type"=>0, "speech"=>"wingilote has a 3.0 KDA playing Miss Fortune Adc in this matchup vs the current average of 2.802169602239589."},
         {"type"=>0, "speech"=>"wingilote has 250.0 CS playing Miss Fortune Adc in this matchup vs the current average of 188.51400651465798."},
         {"type"=>0, "speech"=>"wingilote earns an average of 25000.0 gold playing in this matchup Miss Fortune Adc vs the current average of 12669.788664495114."},
         {"type"=>0, "speech"=>"Here are all the factors I considered for endless white:"},
         {"type"=>0, "speech"=>"endless white has a 20.0% win rate overall playing Caitlyn Adc vs the current average of 48.87%."},
         {"type"=>0, "speech"=>"endless white has a 3.0 KDA overall playing Caitlyn Adc vs the current average of 2.341214808363023."},
         {"type"=>0, "speech"=>"endless white has 250.0 CS overall playing Caitlyn Adc vs the current average of 198.90990635925058."},
         {"type"=>0, "speech"=>"endless white earns an average of 25000.0 gold overall playing Caitlyn Adc vs the current average of 12531.021625685155."},
         {"type"=>0, "speech"=>"endless white is on a 1 game winning streak."},
         {"type"=>0, "speech"=>"endless white has a 20.0% win rate playing Caitlyn Adc in this matchup vs the current average of 45.93%."},
         {"type"=>0, "speech"=>"endless white has a 3.0 KDA playing Caitlyn Adc in this matchup vs the current average of 2.235953089445125."},
         {"type"=>0, "speech"=>"endless white has 250.0 CS playing Caitlyn Adc in this matchup vs the current average of 199.25550488599347."},
         {"type"=>0, "speech"=>"endless white earns an average of 25000.0 gold playing in this matchup Caitlyn Adc vs the current average of 12514.795960912052."}]})
    end
  end

  describe 'POST summoner_matchups' do
    let(:action) { :summoner_matchups }
    let(:summoner_params) do
      {
        summoner: 'Hero man',
        summoner2: 'Other man',
        champion: 'Vayne',
        champion2: 'Sivir',
        region: 'NA1',
        role: 'DUO_CARRY'
      }
    end
    let(:external_response) do
      JSON.parse(File.read('external_response.json'))
        .with_indifferent_access[:summoners][action]
    end

    before :each do
      allow(RiotApi::RiotApi).to receive(:fetch_response).and_return(
        external_response
      )

      @summoner = create(:summoner, name: 'Hero man')
      @summoner2 = create(:summoner, name: 'Other man')
      @summoner3 = create(:summoner, name: 'Other man 2')
      @champion = Champion.new(name: 'Vayne')
      @champion2 = Champion.new(name: 'Sivir')
      @champion3 = Champion.new(name: 'Twitch')
    end

    context 'with one summoner playing an off-meta champion role combination' do
      before :each do
        @off_meta_champion = Champion.new(name: 'Azir')
        summoner_params[:champion2] = @off_meta_champion.name
      end

      context 'with strong performance on the off-meta champion' do
        before :each do
          @matches = create_list(:match, 9)
          match_data = [
            { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: true }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @off_meta_champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
            { match: { win: true }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @off_meta_champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
            { match: { win: true }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @off_meta_champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          ]

          @matches.each_with_index do |match, i|
            summoner_performance = match.summoner_performances.first
            @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
            if match_data[i][:match][:win]
              match.update!(winning_team: summoner_performance.team)
            else
              match.update!(winning_team: @opposing_team)
            end
            summoner_performance.update!(match_data[i][:summoner_performance])
            @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
          end
        end

        it 'should balance out it being off meta' do
          post action, params: params
          expect(speech).to eq 'This one looks fairly close, I am going to give Hero man a performance rating of 84% for this matchup versus Other man with 76%.'
        end
      end

      context 'with weak performance on the off-meta champion' do
        before :each do
          @matches = create_list(:match, 9)
          match_data = [
            { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @off_meta_champion.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @off_meta_champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @off_meta_champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
            { match: { win: false }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @off_meta_champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          ]

          @matches.each_with_index do |match, i|
            summoner_performance = match.summoner_performances.first
            @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
            if match_data[i][:match][:win]
              match.update!(winning_team: summoner_performance.team)
            else
              match.update!(winning_team: @opposing_team)
            end
            summoner_performance.update!(match_data[i][:summoner_performance])
            @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
          end
        end

        it 'should heavily favor the meta opponent' do
          post action, params: params
          expect(speech).to eq 'I would give Hero man playing Vayne a performance rating of 84% for this matchup compared to Other man as Azir who I would rate around 28%. My money is definitely on Hero man this time.'
        end
      end
    end

    context 'with few matches played against that champion by one summoner' do
      before :each do
        @matches = create_list(:match, 9)
        match_data = [
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @champion2.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @champion2.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner2.id, champion_id: @champion2.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
        ]

        @matches.each_with_index do |match, i|
          summoner_performance = match.summoner_performances.first
          @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          if match_data[i][:match][:win]
            match.update!(winning_team: summoner_performance.team)
          else
            match.update!(winning_team: @opposing_team)
          end
          summoner_performance.update!(match_data[i][:summoner_performance])
          @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
        end
      end

      it 'should favor the summoner more with experience in that matchup' do
        post action, params: params
        expect(speech).to eq 'I would give Hero man playing Vayne a performance rating of 88% for this matchup compared to Other man as Sivir who I would rate around 76%. My money is definitely on Hero man this time.'
      end
    end

    context 'with few games played on that champion by one summoner' do
      before :each do
        @matches = create_list(:match, 6)
        match_data = [
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
        ]

        @matches.each_with_index do |match, i|
          summoner_performance = match.summoner_performances.first
          @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          if match_data[i][:match][:win]
            match.update!(winning_team: summoner_performance.team)
          else
            match.update!(winning_team: @opposing_team)
          end
          summoner_performance.update!(match_data[i][:summoner_performance])
          @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
        end
      end

      it 'should favor the summoner more experienced with their champion' do
        post action, params: params
        expect(speech).to eq 'I would give Hero man playing Vayne a performance rating of 75% for this matchup compared to Other man as Sivir who I would rate around 64%. My money is definitely on Hero man this time.'
      end
    end

    context 'with no games played on that champion by one summoner' do
      before :each do
        @matches = create_list(:match, 6)
        match_data = [
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion3.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner3.id, role: 'DUO_CARRY' } },
        ]

        @matches.each_with_index do |match, i|
          summoner_performance = match.summoner_performances.first
          @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          if match_data[i][:match][:win]
            match.update!(winning_team: summoner_performance.team)
          else
            match.update!(winning_team: @opposing_team)
          end
          summoner_performance.update!(match_data[i][:summoner_performance])
          @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
        end
      end

      it 'should heavily favor the summoner with experience on their champion' do
        post action, params: params
        expect(speech).to eq 'I would give Hero man playing Vayne a performance rating of 79% for this matchup compared to Other man as Sivir who I would rate around 52%. My money is definitely on Hero man this time.'
      end
    end

    context 'with strong performance on that champion by one summoner' do
      before :each do
        @matches = create_list(:match, 5)
        match_data = [
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
        ]

        @matches.each_with_index do |match, i|
          summoner_performance = match.summoner_performances.first
          @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          if match_data[i][:match][:win]
            match.update!(winning_team: summoner_performance.team)
          else
            match.update!(winning_team: @opposing_team)
          end
          summoner_performance.update!(match_data[i][:summoner_performance])
          @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
        end
      end

      it 'should favor the strong performer' do
        post action, params: params
        expect(speech).to eq 'I would give Hero man playing Vayne a performance rating of 95% for this matchup compared to Other man as Sivir who I would rate around 54%. My money is definitely on Hero man this time.'
      end
    end

    context 'with even performance' do
      before :each do
        @matches = create_list(:match, 6)
        match_data = [
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
        ]

        @matches.each_with_index do |match, i|
          summoner_performance = match.summoner_performances.first
          @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          if match_data[i][:match][:win]
            match.update!(winning_team: summoner_performance.team)
          else
            match.update!(winning_team: @opposing_team)
          end
          summoner_performance.update!(match_data[i][:summoner_performance])
          @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
        end
      end

      it 'should indicate that it is unsure who to favor' do
        post action, params: params
        expect(speech).to eq 'This one looks fairly close, I am going to give Hero man a performance rating of 87% for this matchup versus Other man with 80%.'
      end
    end

    context 'with one player tilted' do
      before :each do
        @matches = create_list(:match, 9)
        match_data = [
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: true }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
          { match: { win: false }, summoner_performance: { summoner_id: @summoner.id, champion_id: @champion.id, role: 'DUO_CARRY' }, opponent: { champion_id: @champion2.id, summoner_id: @summoner2.id, role: 'DUO_CARRY' } },
        ]

        @matches.each_with_index do |match, i|
          summoner_performance = match.summoner_performances.first
          @opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
          if match_data[i][:match][:win]
            match.update!(winning_team: summoner_performance.team)
          else
            match.update!(winning_team: @opposing_team)
          end
          summoner_performance.update!(match_data[i][:summoner_performance])
          @opposing_team.summoner_performances.first.update!(match_data[i][:opponent])
        end
      end

      it 'should favor the non-tilted player' do
        post action, params: params
        expect(speech).to eq 'I would give Hero man playing Vayne a performance rating of 62% for this matchup compared to Other man as Sivir who I would rate around 81%. My money is definitely on Other man this time.'
      end
    end
  end

  describe 'POST teammates' do
    let(:action) { :teammates }
    let(:summoner_params) do
      {
        name: 'Hero man',
        champion: 'Shyvana',
        region: 'NA1',
        role: '',
        list_order: 'highest',
        metric: '',
        position_details: '',
        time: ''
      }
    end

    before :each do
      @matches = create_list(:match, 5)
      summoner = create(:summoner, name: 'Hero man')
      teammate_summoner = create(:summoner, name: 'Teammate man')
      other_summoner = create(:summoner, name: 'Other man')
      match_data = [
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, teammate: { summoner_id: teammate_summoner.id } },
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, teammate: { summoner_id: teammate_summoner.id } },
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, teammate: { summoner_id: teammate_summoner.id } },
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, teammate: { summoner_id: other_summoner.id } },
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, teammate: { summoner_id: other_summoner.id } },
      ]
      @matches.each_with_index do |match, i|
        summoner_performance = match.team1.summoner_performances.first
        teammate_performance = match.team1.summoner_performances.last
        opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
        if match_data[i][:match][:win]
          match.update!(winning_team: summoner_performance.team)
        else
          match.update!(winning_team: opposing_team)
        end
        summoner_performance.update!(
          match_data[i][:summoner_performance].merge({ summoner_id: summoner.id })
        )
        teammate_performance.update!(match_data[i][:teammate])
      end
    end

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq 'The teammate who has helped Hero man get the highest win rate from Wed Feb 7 at 12am to Thu Feb 8 at 12am playing Shyvana Jungle is Teammate man.'
      end
    end

    context 'with no champion specified' do
      before :each do
        summoner_params[:champion] = ''
      end

      it 'should specify the highest win rate teammates for the summoner across champions' do
        post action, params: params
        expect(speech).to eq 'The teammate who has helped Hero man get the highest win rate Jungle is Teammate man.'
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
        end

        context 'with one role' do
          it 'should specify the highest win rate teammates for the summoner independent of role or champion' do
            post action, params: params
            expect(speech).to eq 'The teammate who has helped Hero man get the highest win rate Jungle is Teammate man.'
          end
        end

        context 'with multiple roles' do
          before :each do
            @matches.first.summoner_performances.first.update(role: 'DUO_SUPPORT')
          end

          it 'should not include the roles' do
            post action, params: params
            expect(speech).to eq 'The teammate who has helped Hero man get the highest win rate across Jungle and Support is Teammate man.'
          end
        end
      end
    end

    context 'with no summoners returned' do
      context 'with no position offset' do
        before :each do
          summoner_params[:name] = 'Inactive player'
        end

        it 'should indicate the summoner has not played any games' do
          post action, params: params
          expect(speech).to eq 'Inactive player is not an active player in ranked.'
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 10000
        end

        it 'should indicate that the summoner has not played enough games' do
          post action, params: params
          expect(speech).to eq 'Hero man has played with seventeen summoners as Shyvana Jungle.'
        end

        context 'with a role' do
          before :each do
            summoner_params[:role] = 'JUNGLE'
          end

          it 'should indicate that the summoner has not played enough games in that role' do
            post action, params: params
            expect(speech).to eq 'Hero man has played with seventeen summoners as Shyvana Jungle.'
          end
        end
      end
    end

    context 'with a single summoner returned' do
      before :each do
        summoner_params[:list_size] = 1
      end

      context 'with complete results' do
        it 'should return the single teammate' do
          post action, params: params
          expect(speech).to eq 'The teammate who has helped Hero man get the highest win rate playing Shyvana Jungle is Teammate man.'
        end

        context 'with a position offset' do
          before :each do
            summoner_params[:list_position] = 2
          end

          it 'should return the offset single teammate' do
            post action, params: params
            expect(speech).to eq 'The teammate who has helped Hero man get the second highest win rate playing Shyvana Jungle is Other man.'
          end
        end

        context 'with a role specified' do
          before :each do
            summoner_params[:role] = 'JUNGLE'
          end

          it 'should return the single teammate' do
            post action, params: params
            expect(speech).to eq 'The teammate who has helped Hero man get the highest win rate playing Shyvana Jungle is Teammate man.'
          end
        end
      end

      context 'with incomplete results' do
        before :each do
          summoner_params[:list_position] = 17
          summoner_params[:list_size] = 2
        end

        it 'should return the single teammate' do
          post action, params: params
          expect(speech).to start_with 'Hero man has only played with seventeen summoners as Shyvana Jungle. The summoner who has helped Hero man get the seventeenth highest win rate is '
        end

        context 'with a role' do
          before :each do
            summoner_params[:role] = 'JUNGLE'
          end

          it 'should return the single teammate' do
            post action, params: params
            expect(speech).to start_with 'Hero man has only played with seventeen summoners as Shyvana Jungle. The summoner who has helped Hero man get the seventeenth highest win rate is '
          end
        end
      end
    end

    context 'with multiple summoners returned' do
      before :each do
        summoner_params[:list_size] = 2
      end

      context 'with no position offset' do
        context 'with complete results' do
          it 'should determine the best teammates' do
            post action, params: params
            expect(speech).to eq 'The teammates who have helped Hero man get the highest win rate playing Shyvana Jungle are Teammate man and Other man.'
          end

          context 'with a role' do
            before :each do
              summoner_params[:role] = 'JUNGLE'
            end

            it 'should filter teammates by champion role' do
              post action, params: params
              expect(speech).to eq 'The teammates who have helped Hero man get the highest win rate playing Shyvana Jungle are Teammate man and Other man.'
            end
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 100
          end

          it 'should return the teammates, indicating that the list is incomplete' do
            post action, params: params
            expect(speech).to start_with 'Hero man has only played with seventeen summoners as Shyvana Jungle. The summoners who have helped Hero man get the highest win rate are '
          end

          context 'with a role' do
            before :each do
              summoner_params[:role] = 'JUNGLE'
            end

            it 'should filter teammates by champion role' do
              post action, params: params
              expect(speech).to start_with 'Hero man has only played with seventeen summoners as Shyvana Jungle. '
            end
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
        end

        context 'with complete results' do
          it 'should return the summoners at the offset' do
            post action, params: params
            expect(speech).to start_with 'The teammates who have helped Hero man get the second through third highest win rate playing Shyvana Jungle are Other man'
          end

          context 'with a role' do
            before :each do
              summoner_params[:role] = 'JUNGLE'
            end

            it 'should filter teammates by champion role' do
              post action, params: params
              expect(speech).to start_with 'The teammates who have helped Hero man get the second through third highest win rate playing Shyvana Jungle are '
            end
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 100
          end

          it 'should return the summoners, indicating this is not the full list' do
            post action, params: params
            expect(speech).to start_with 'Hero man has only played with seventeen summoners as Shyvana Jungle. The summoners who have helped Hero man get the second through seventeenth'
          end

          context 'with a role' do
            before :each do
              summoner_params[:role] = 'JUNGLE'
            end

            it 'should filter teammates by champion role' do
              post action, params: params
              expect(speech).to start_with 'Hero man has only played with seventeen summoners as Shyvana Jungle. '
            end
          end
        end
      end
    end
  end

  describe 'POST champion_matchups' do
    let(:action) { :champion_matchups }
    let(:summoner_params) do
      {
        name: 'Hero man',
        champion: 'Shyvana',
        champion2: 'Udyr',
        region: 'NA1',
        role: 'JUNGLE',
        list_order: 'highest',
        metric: '',
        position_details: '',
        time: ''
      }
    end

    before :each do
      @matches = create_list(:match, 2)
      match_data = [
        { match: { win: true }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, opponent: { champion_id: 77 } },
        { match: { win: false }, summoner_performance: { champion_id: 102, role: 'JUNGLE' }, opponent: { champion_id: 50 } },
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

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Shyvana Jungle one time against Udyr from Wed Feb 7 at 12am to Thu Feb 8 at 12am with a 100.0% win rate.'
      end
    end

    context 'with no own champion specified' do
      before :each do
        summoner_params[:champion] = ''
      end

      it 'should determine the matchup for the summoner against that champion in general' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Jungle one time against Udyr with a 100.0% win rate.'
      end
    end

    context 'with no games against that champion' do
      before :each do
        summoner_params[:champion2] = 'Bard'
      end

      it 'should indicate that the summoner has not played against that champion' do
        post action, params: params
        expect(speech).to eq 'I could not find any matches for Hero man playing Shyvana Jungle against Bard. It would be interesting to see though.'
      end
    end

    context 'with no position or metric' do
      it 'should indicte the win rate the summoner gets playing that matchup' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Shyvana Jungle one time against Udyr with a 100.0% win rate.'
      end
    end

    context 'with a position' do
      before :each do
        summoner_params[:position_details] = :kills
      end

      it 'should indicate the kills the summoner gets playing that matchup' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Shyvana Jungle one time against Udyr and averages 2.0 kills.'
      end
    end

    context 'with a metric' do
      context 'with a KDA metric' do
        before :each do
          summoner_params[:metric] = :KDA
        end

        it 'should indicate the KDA the summoner gets playing that matchup' do
          post action, params: params
          expect(speech).to eq 'Hero man has played Shyvana Jungle one time against Udyr with an overall 2.0/3.0/7.0 KDA.'
        end
      end

      context 'with a count metric' do
        before :each do
          summoner_params[:metric] = :count
        end

        it 'should indicate the count the summoner gets playing that matchup' do
          post action, params: params
          expect(speech).to eq 'Hero man has played Shyvana Jungle one time against Udyr.'
        end
      end

      context 'with a winrate metric' do
        before :each do
          summoner_params[:metric] = :winrate
        end

        it 'should indicate the win rate the summoner gets playing that matchup' do
          post action, params: params
          expect(speech).to eq 'Hero man has played Shyvana Jungle one time against Udyr with a 100.0% win rate.'
        end
      end
    end
  end

  describe 'POST champion_spells' do
    let(:action) { :champion_spells }
    let(:summoner_params) do
      {
        name: 'Hero man',
        champion: 'Shyvana',
        region: 'NA1',
        role: 'DUO_CARRY',
        list_order: 'highest',
        metric: '',
        position_details: '',
        time: ''
      }
    end

    before :each do
      match_data = [
        { match: { win: true }, summoner_performance: { spell1_id: 3, spell2_id: 4, champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { spell1_id: 3, spell2_id: 4, champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { spell1_id: 3, spell2_id: 4, champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { spell1_id: 3, spell2_id: 4, champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, summoner_performance: { spell1_id: 3, spell2_id: 4, champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, summoner_performance: { spell1_id: 4, spell2_id: 6, champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, summoner_performance: { spell1_id: 4, spell2_id: 6, champion_id: 102, role: 'DUO_CARRY' } },
      ]

      @matches = create_list(:match, match_data.length)
      summoner = create(:summoner, name: 'Hero man')

      @matches.each_with_index do |match, i|
        summoner_performance = match.summoner_performances.first
        opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
        winning_team = match_data[i][:match][:win] ? summoner_performance.team : opposing_team
        match.update!(winning_team: winning_team)
        summoner_performance.update!(match_data[i][:summoner_performance].merge({ summoner_id: summoner.id }))
      end
    end

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq 'The spell combination used by Hero man from Wed Feb 7 at 12am to Thu Feb 8 at 12am that gives the summoner playing Shyvana Adc the highest win rate is Exhaust and Flash.'
      end
    end

    context 'with no champion specified' do
      before :each do
        summoner_params[:champion] = ''
      end

      it 'should determine the spells for the summoner in general' do
        post action, params: params
        expect(speech).to eq 'The spell combination used by Hero man that gives the summoner playing Adc the highest win rate is Exhaust and Flash.'
      end
    end

    context 'with no spell combinations' do
      context 'with no position offset' do
        before :each do
          summoner_params[:name] = 'inactive player'
        end

        it 'should indicate the summoner never plays that champion' do
          post action, params: params
          expect(speech).to eq 'inactive player is not an active player in ranked.'
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 100
        end

        it 'should indicate that no spell combinations were requested' do
          post action, params: params
          expect(speech).to eq 'Hero man only has used two spell combinations playing as Shyvana Adc this season.'
        end
      end
    end

    context 'with a single spell combination' do
      context 'with no position offset' do
        it 'should determine the single spell combination' do
          post action, params: params
          expect(speech).to eq 'The spell combination used by Hero man that gives the summoner playing Shyvana Adc the highest win rate is Exhaust and Flash.'
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
        end

        it 'should determine the single spell combination at that offset' do
          post action, params: params
          expect(speech).to eq 'The spell combination used by Hero man that gives the summoner playing as Shyvana Adc the second highest win rate is Flash and Ghost.'
        end
      end
    end
  end

  describe 'POST champion_bans' do
    let(:action) { :champion_bans }
    let(:summoner_params) do
      {
        name: 'Hero man',
        champion: 'Shyvana',
        region: 'NA1',
        role: 'DUO_CARRY',
        list_order: 'highest',
        list_size: 1,
        metric: '',
        position_details: '',
        time: ''
      }
    end

    before :each do
      match_data = [
        { match: { win: true }, ban: { champion_id: 42 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, ban: { champion_id: 42 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, ban: { champion_id: 42 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, ban: { champion_id: 42 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, ban: { champion_id: 42 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, ban: { champion_id: 45 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: true }, ban: { champion_id: 45 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, ban: { champion_id: 41 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, ban: { champion_id: 41 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, ban: { champion_id: 41 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
        { match: { win: false }, ban: { champion_id: 41 }, summoner_performance: { champion_id: 102, role: 'DUO_CARRY' } },
      ]

      @matches = create_list(:match, match_data.length)
      summoner = create(:summoner, name: 'Hero man')

      @matches.each_with_index do |match, i|
        summoner_performance = match.summoner_performances.first
        opposing_team = summoner_performance.team == match.team1 ? match.team2 : match.team1
        winning_team = match_data[i][:match][:win] ? summoner_performance.team : opposing_team
        match.update!(winning_team: winning_team)
        summoner_performance.update!(match_data[i][:summoner_performance].merge({ summoner_id: summoner.id }))
        summoner_performance.ban.update!(match_data[i][:ban])
      end
    end

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq 'The ban by Hero man playing Shyvana Adc that gives the summoner the highest win rate from Wed Feb 7 at 12am to Thu Feb 8 at 12am is Corki.'
      end
    end

    context 'with no champion specified' do
      before :each do
        summoner_params[:champion] = ''
      end

      it 'should determine the best ban for the summoner in the given role for any champion' do
        post action, params: params
        expect(speech).to eq 'The ban by Hero man Adc that gives the summoner the highest win rate is Corki.'
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
        end

        context 'with a single role played' do
          it 'should determine the best ban for the summoner in their only played role' do
            post action, params: params
            expect(speech).to eq 'The ban by Hero man Adc that gives the summoner the highest win rate is Corki.'
          end
        end

        context 'with multiple roles played' do
          before :each do
            @matches.first.summoner_performances.first.update(role: 'DUO_SUPPORT')
          end

          it 'should determine the best ban for the summoner regardless of role' do
            post action, params: params
            expect(speech).to eq 'The ban by Hero man across Adc and Support that gives the summoner the highest win rate is Corki.'
          end
        end
      end
    end

    context 'with no champions returned' do
      context 'with no position offset' do
        before :each do
          summoner_params[:name] = 'inactive player'
        end

        it 'should indicate the summoner has not played any games as that champion this season' do
          post action, params: params
          expect(speech).to eq 'inactive player is not an active player in ranked.'
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

          it 'should indicate that they did not ask for any bans' do
            post action, params: params
            expect(speech).to eq 'No bans were requested.'
          end
        end

        context 'with incomplete results' do
          it 'should indicate that the summoner has not banned enough champions' do
            post action, params: params
            expect(speech).to eq 'Hero man has only banned three champions playing as Shyvana Adc.'
          end
        end
      end
    end

    context 'with a single champion returned' do
      context 'with no position offset' do
        context 'with complete results' do
          it 'should specify the a ban' do
            post action, params: params
            expect(speech).to eq 'The ban by Hero man playing Shyvana Adc that gives the summoner the highest win rate is Corki.'
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:name] = 'inactive player'
          end

          it 'should indicate that the summoner has not played that champion this season' do
            post action, params: params
            expect(speech).to eq 'inactive player is not an active player in ranked.'
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
        end

        context 'with complete results' do
          it 'should return the offset ban' do
            post action, params: params
            expect(speech).to eq 'The ban by Hero man that gives the summoner playing Shyvana Adc the second highest win rate is Veigar.'
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_position] = 100
          end

          it 'should indicate the summoner has not banned enough champions' do
            post action, params: params
            expect(speech).to eq 'Hero man has only banned three champions playing as Shyvana Adc.'
          end
        end
      end
    end

    context 'with multiple champions returned' do
      before :each do
        summoner_params[:list_size] = 2
      end

      context 'without a position offset' do
        context 'with complete results' do
          it 'should specify the bans' do
            post action, params: params
            expect(speech).to eq 'The bans by Hero man playing Shyvana Adc that give the summoner the highest win rate are Corki and Veigar.'
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 5
          end

          it 'should return the bans indicating it is incomplete' do
            post action, params: params
            expect(speech).to eq 'Hero man has only played against three different champions as Shyvana Adc. The bans that give the summoner the highest win rate are Corki, Veigar, and Gangplank.'
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
        end

        context 'with complete results' do
          it 'should specify all the bans' do
            post action, params: params
            expect(speech).to eq 'The second through third bans that give Hero man playing Shyvana Adc the highest win rate are Veigar and Gangplank.'
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 5
          end

          it 'should return the bans indicating that it is incomplete' do
            post action, params: params
            expect(speech).to eq 'Hero man has only played against three different champions as Shyvana Adc. The second through third bans that give the highest win rate are Veigar and Gangplank.'
          end
        end
      end
    end
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
        time: ''
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

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times from Wed Feb 7 at 12am to Thu Feb 8 at 12am and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with no role specified' do
      before :each do
        summoner_params[:role] = ''
      end

      context 'with a single role played' do
        it 'should determine builds for the single role' do
          post action, params: params
          expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
        end
      end

      context 'with multiple roles played' do
        before :each do
          @matches.first.summoner_performances.first.update_attribute(:role, 'JUNGLE')
        end

        it 'should indicate that the summoner has played the champion in multiple roles' do
          post action, params: params
          expect(speech).to eq "Hero man has played Shyvana across Adc and Jungle eleven times and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
        end
      end
    end

    context 'when the champion has not been played' do
      before :each do
        @matches.each do |match|
          match.summoner_performances.first.update_attribute(:champion_id, 101)
        end
      end

      it 'should indicate that the summoner has not played the champion' do
        post action, params: params
        expect(speech).to eq "Hero man has not played any games as Shyvana Adc."
      end
    end

    context 'without a metric or position details specified' do
      it 'should use winrate as the default metric' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a position details specified' do
      before :each do
        summoner_params[:position_details] = :penta_kills
        @matches.first.summoner_performances.first.update!(penta_kills: 100000000)
      end

      it 'should use the position details to determine the build' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest penta kills build is two Rabadon's Deathcaps, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a reverse list order' do
      before :each do
        summoner_params[:list_order] = 'lowest'
      end

      it 'should return the worst build' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's lowest win rate build is two Rabadon's Deathcaps, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a winrate metric specified' do
      before :each do
        summoner_params[:metric] = :winrate
      end

      it 'should use winrate as the build metric' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest win rate build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
      end
    end

    context 'with a KDA metric specified' do
      before :each do
        summoner_params[:metric] = :KDA
        @matches.first.summoner_performances.first.update!(kills: 100000000)
      end

      context 'with all valid KDA performances' do
        it 'should use KDA as the build metric' do
          post action, params: params
          expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest KDA build is two Rabadon's Deathcaps, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
        end
      end

      context 'with infinite KDA performances' do
        before :each do
          @matches.first.summoner_performances.first.update!(deaths: 0, kills: 10, assists: 0)
        end

        it 'should filter out zero performances' do
          post action, params: params
          expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest KDA build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
        end
      end

      context 'with NAN KDA performances' do
        before :each do
          @matches.first.summoner_performances.first.update!(deaths: 0, kills: 0, assists: 0)
        end

        it 'should filter out zero performances' do
          post action, params: params
          expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest KDA build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
        end
      end
    end

    context 'with a count metric specified' do
      before :each do
        summoner_params[:metric] = :count
      end

      it 'should use the frequency of the build as the metric' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest games played build is Rabadon's Deathcap, Statikk Shiv, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
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
        expect(speech).to eq 'Hero man does not have any complete builds playing Shyvana Adc.'
      end
    end

    context 'with builds with the same winrate' do
      before :each do
        build = @complete_build2
        summoner_performance = @matches[2].summoner_performances.first
        build.each_with_index do |item_id, index|
          summoner_performance.update_attribute("item#{index}_id", item_id)
        end
      end

      it 'should use the build that is done most frequently' do
        post action, params: params
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest win rate build is two Rabadon's Deathcaps, Runaan's Hurricane, Warmog's Armor, Eye of the Equinox, and Zz'Rot Portal."
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
        expect(speech).to eq "Hero man has played Shyvana Adc eleven times and the summoner's highest win rate build is Zz'Rot Portal, Eye of the Equinox, Warmog's Armor, Runaan's Hurricane, Statikk Shiv, and Rabadon's Deathcap."
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

    context 'with no queue data' do
      before :each do
        allow_any_instance_of(Summoner).to receive(:queue).and_return(RankedQueue.new(nil))
      end

      it 'should inform the user their queue data could not be found' do
        post action, params: params
        expect(speech).to eq 'I could not find any information on Wingilote from the Riot overlords in ranked solo queue. The summoner may not have played enough games or there may be something going on with the system. Sorry about that, try again later.'
      end
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
        expect(speech).to eq 'inactive player is not an active player in ranked.'
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

  describe 'POST champion_counters' do
    let(:action) { :champion_counters }
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
        time: ''
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

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq 'The champions with the highest win rate against Hero man from Wed Feb 7 at 12am to Thu Feb 8 at 12am playing Shyvana Middle are Swain and Elise.'
      end
    end

    context 'with no role specified' do
      before :each do
        summoner_params[:role] = ''
      end

      it 'should ask for a role' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Shyvana this season across Adc, Jungle, and Middle. Which role do you want to know about?'
      end
    end

    context 'with no champion specified' do
      before :each do
        summoner_params[:champion] = ''
      end

      it 'should determine counters for the summoner in the provided role' do
        post action, params: params
        expect(speech).to eq 'The champions with the highest win rate against Hero man playing Middle are Swain and Elise.'
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

      it 'should indicate that there have been no opponents this season' do
        post action, params: params
        expect(speech).to eq 'I could not find any matches for Hero man playing Shyvana Middle this season. A shame, I enjoy watching Shyvana play.'
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
          expect(speech).to eq 'inactive player is not an active player in ranked.'
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
          it 'should indicate that the summoner has not played against that many champions' do
            post action, params: params
            expect(speech).to eq 'Hero man has only played against two champions playing as Shyvana Middle.'
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

          it 'should return the single champion' do
            post action, params: params
            expect(speech).to eq 'The champion with the highest win rate playing against Hero man as Shyvana Middle is Swain.'
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:role] = 'DUO_CARRY'
          end

          it 'should return the single champion, indicating the list is incomplete' do
            post action, params: params
            expect(speech).to eq 'Hero man has only played against one champion as Shyvana Adc. The champion with the highest win rate playing against Hero man as Shyvana Adc is Janna.'
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

          it 'should return the single champion' do
            post action, params: params
            expect(speech).to eq 'The champion with the second highest win rate playing against Hero man as Shyvana Middle is Elise.'
          end
        end

        context 'with incomplete results' do
          it 'should return the single champion and indicate the results are not complete' do
            post action, params: params
            expect(speech).to eq 'Hero man has only played against two different champions as Shyvana Middle. The champion with the second highest win rate playing against Hero man as Shyvana Middle is Elise.'
          end
        end
      end
    end

    context 'with multiple results returned' do
      context 'with no position offset' do
        context 'with complete results' do
          it 'should return the list of champions' do
            post action, params: params
            expect(speech).to eq 'The champions with the highest win rate against Hero man playing Shyvana Middle are Swain and Elise.'
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 4
          end

          it 'should return the list of champions indicating it is incomplete' do
            post action, params: params
            expect(speech).to eq 'Hero man has only played against two different champions as Shyvana Middle. The champions with the highest win rate playing against Hero man as Shyvana Middle are Swain and Elise.'
          end
        end
      end

      context 'with a position offset' do
        before :each do
          summoner_params[:list_position] = 2
          summoner_params[:role] = 'JUNGLE'
        end

        context 'with complete results' do
          it 'should return the complete list of champions' do
            post action, params: params
            expect(speech).to eq 'The second through third champions with the highest win rate against Hero man playing Shyvana Jungle are Swain and Janna.'
          end
        end

        context 'with incomplete results' do
          before :each do
            summoner_params[:list_size] = 5
          end

          it 'should return the list of champions, indicating that it is incomplete' do
            post action, params: params
            expect(speech).to eq 'Hero man has only played against three different champions as Shyvana Jungle. The second through third champions with the highest win rate against Hero man playing as Shyvana Jungle are Swain and Janna.'
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
        time: ''
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

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq "The champions played by Hero man from Wed Feb 7 at 12am to Thu Feb 8 at 12am with the summoner's highest win rate across Adc, Jungle, and Middle are Nunu and Tristana."
      end
    end

    context 'with a metric and position details specified' do
      before :each do
        summoner_params[:metric] = :count
        summoner_params[:position_details] = 'kills'
      end

      it 'should sort the ranking by the metric' do
        post action, params: params
        expect(speech).to eq "The champions played by Hero man with the summoner's highest games played across Adc, Jungle, and Middle are Tristana and Nunu."
      end
    end

    context 'with only a metric specified' do
      context 'with a count metric given' do
        before :each do
          summoner_params[:metric] = :count
        end

        it 'should rank by games played' do
          post action, params: params
          expect(speech).to eq "The champions played by Hero man with the summoner's highest games played across Adc, Jungle, and Middle are Tristana and Nunu."
        end
      end

      context 'with a KDA metric given' do
        before :each do
          Match.last.summoner_performances.first.update!(kills: 10000)
          summoner_params[:metric] = :KDA
        end

        it 'should rank by average KDA' do
          post action, params: params
          expect(speech).to eq "The champions played by Hero man with the summoner's highest KDA across Adc, Jungle, and Middle are Tristana and Nunu."
        end
      end

      context 'with a winrate metric given' do
        before :each do
          summoner_params[:metric] = :winrate
        end

        it 'should rank by overall winrate' do
          post action, params: params
          expect(speech).to eq "The champions played by Hero man with the summoner's highest win rate across Adc, Jungle, and Middle are Nunu and Tristana."
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
        expect(speech).to eq "The champions played by Hero man with the summoner's highest wards placed across Adc, Jungle, and Middle are Tristana and Nunu."
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

            it 'should indicate that the summoner has not played in that role' do
              post action, params: params
              expect(speech).to eq 'Hero man has not played any games Top.'
            end
          end

          context 'with no role specified' do
            before :each do
              summoner_params[:name] = 'inactive player'
            end

            it 'should indicate that the summoner has not played this season.' do
              post action, params: params
              expect(speech).to eq 'inactive player is not an active player in ranked.'
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

            it 'should indicate that the summoner has not played offset champions this season in that role' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played two champions Jungle.'
            end
          end

          context 'with no role specified' do
            it 'should indicate that the summoner has not played offset champions this season' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played two champions across Adc, Jungle, and Middle.'
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

            it 'should return the single highest ranking for that role' do
              post action, params: params
              expect(speech).to eq 'The champion played by Hero man with the highest win rate Middle is Nunu.'
            end
          end

          context 'with no role specified' do
            it 'should return the single highest ranking for any role' do
              post action, params: params
              expect(speech).to eq 'The champion played by Hero man with the highest win rate across Adc, Jungle, and Middle is Nunu.'
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

            it 'should indicate that the player is inactive this season' do
              post action, params: params
              expect(speech).to eq 'inactive player is not an active player in ranked.'
            end
          end

          context 'with no role specified' do
            it 'should indicate that the player is inactive this season' do
              post action, params: params
              expect(speech).to eq 'inactive player is not an active player in ranked.'
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

            it 'should return the offset highest champion for that role' do
              post action, params: params
              expect(speech).to eq 'The champion played by Hero man with the second highest win rate Middle is Tristana.'
            end
          end

          context 'with no role specified' do
            it 'should return the offset highest champion for any role' do
              post action, params: params
              expect(speech).to eq 'The champion played by Hero man with the second highest win rate across Adc, Jungle, and Middle is Tristana.'
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

            it 'should indicate the results are incomplete and return the one champion for that role' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played two champions Middle. The champion played by Hero man with the second highest win rate is Tristana.'
            end
          end

          context 'with no role specified' do
            it 'should indicate the results are incomplete and return the one champion' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played two champions across Adc, Jungle, and Middle. The champion played by Hero man with the second highest win rate is Tristana.'
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

            it 'should provide rankings for the champions in that role' do
              post action, params: params
              expect(speech).to eq "The champions played by Hero man with the summoner's highest win rate Middle are Nunu and Tristana."
            end
          end

          context 'with no role specified' do
            it 'should provide rankings for the champions in any role' do
              post action, params: params
              expect(speech).to eq "The champions played by Hero man with the summoner's highest win rate across Adc, Jungle, and Middle are Nunu and Tristana."
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

            it 'should return an incomplete ranking of champions in that role' do
              post action, params: params
              expect(speech).to eq "Hero man has only played two champions Middle. The champions played by Hero man with the summoner's highest win rate are Nunu and Tristana."
            end
          end

          context 'with no role specified' do
            it 'should return an incomplete ranking of champions in any role' do
              post action, params: params
              expect(speech).to eq "Hero man has only played two champions across Adc, Jungle, and Middle. The champions played by Hero man with the summoner's highest win rate are Nunu and Tristana."
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

            it 'should return a complete ranking with champions from that role' do
              post action, params: params
              expect(speech).to eq 'The second through third champions played by Hero man with the highest win rate Middle are Karthus and Tristana.'
            end
          end

          context 'with no role specified' do
            it 'should return a complete ranking with champions from all roles' do
              post action, params: params
              expect(speech).to eq 'The second through third champions played by Hero man with the highest win rate across Adc, Jungle, and Middle are Tristana and Karthus.'
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

            it 'should return incomplete rankings for that role' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played three champions Middle. The second through third champions played by Hero man with the highest win rate are Karthus and Tristana.'
            end
          end

          context 'with no role specified' do
            it 'should return incomplete rankings across all roles' do
              post action, params: params
              expect(speech).to eq 'Hero man has only played three champions across Adc, Jungle, and Middle. The second through third champions played by Hero man with the highest win rate are Tristana and Karthus.'
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
        time: ''
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

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Tristana Adc two times from Wed Feb 7 at 12am to Thu Feb 8 at 12am with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
      end
    end

    context 'with no games played as that champion' do
      context 'with a role specified' do
        before :each do
          summoner_params[:role] = 'TOP'
        end

        it 'should indicate that the summoner has not played the champion in that role' do
          post action, params: params
          expect(speech).to eq 'Hero man has not played any games as Tristana Top.'
        end
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
          summoner_params[:champion] = 'Zed'
        end

        it 'should indicate that the summoner has not played the champion this season' do
          post action, params: params
          expect(speech).to eq 'Hero man has not played any games as Zed.'
        end
      end
    end

    context 'with games played as that champion' do
      context 'with a role specified' do
        it 'should determine the win rate and KDA for the specified role' do
          post action, params: params
          expect(speech).to eq 'Hero man has played Tristana Adc two times with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
        end
      end

      context 'with no role specified' do
        let(:summoner_params) do
          { name: 'Hero man', region: 'NA1', champion: 'Tristana', role: '', time: '' }
        end

        context 'with one role' do
          it 'should determine the win rate and KDA for the one role' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana Adc two times with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
          end
        end

        context 'with multiple roles' do
          before :each do
            @match2.summoner_performances.first.update(role: 'DUO_SUPPORT')
          end

          it 'should indicate the value is aggregated over multiple roles' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana across Adc and Support two times with a 100.0% win rate and an overall 2.0/3.0/7.0 KDA.'
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
        time: '',
        metric: ''
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

    context 'with a time specified' do
      before :each do
        summoner_params[:time] = @today
      end

      it 'should indicate that the teammates are from games in the time interval' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Tristana Adc two times from Wed Feb 7 at 12am to Thu Feb 8 at 12am and averages 2.0 kills.'
      end
    end

    context 'with no role specified' do
      before :each do
        summoner_params[:role] = ''
      end

      context 'with a single role played' do
        it 'should determine the position value for the summoner' do
          post action, params: params
          expect(speech).to eq 'Hero man has played Tristana Adc two times and averages 2.0 kills.'
        end
      end

      context 'with multiple roles played' do
        before :each do
          @match1.summoner_performances.first.update(role: 'DUO_SUPPORT')
        end

        it 'should determine the position value for the summoner across multiple roles' do
          post action, params: params
          expect(speech).to eq 'Hero man has played Tristana across Adc and Support two times and averages 2.0 kills.'
        end

        context 'with no champion specified' do
          before :each do
            summoner_params[:champion] = ''
          end

          it 'should determine the value in the given role regardless of champion and role' do
            post action, params: params
            expect(speech).to eq 'Hero man has played across Adc and Support two times and averages 2.0 kills.'
          end
        end
      end
    end

    context 'with no champion specified' do
      before :each do
        summoner_params[:champion] = ''
      end

      it 'should determine the value in the given role regardless of champion' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Adc two times and averages 2.0 kills.'
      end
    end

    context 'with a winrate metric specified' do
      before :each do
        summoner_params[:metric] = :winrate
      end

      it 'should indicate the winrate for the summoner playing that champion' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Tristana Adc two times and has a 100.0% overall win rate.'
      end
    end

    context 'with a count metric specified' do
      before :each do
        summoner_params[:metric] = :count
      end

      it 'should indicate the count for the summoner playing that champion' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Tristana Adc two times.'
      end
    end

    context 'with a KDA metric specified' do
      before :each do
        summoner_params[:metric] = :KDA
      end

      it 'should indicate the KDA for the summoner playing that champion' do
        post action, params: params
        expect(speech).to eq 'Hero man has played Tristana Adc two times and averages a 2.0/3.0/7.0 KDA.'
      end
    end

    context 'with no games played as that champion' do
      context 'with a role specified' do
        before :each do
          summoner_params[:role] = 'TOP'
        end

        it 'should indicate that the summoner has not played the champion in that role' do
          post action, params: params
          expect(speech).to eq 'Hero man has not played any games as Tristana Top.'
        end
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
          summoner_params[:champion] = 'Zed'
        end

        it 'should indicate that the summoner has not played the champion this season' do
          post action, params: params
          expect(speech).to eq 'Hero man has not played any games as Zed.'
        end
      end
    end

    context 'with games played as that champion' do
      context 'with a role specified' do
        it 'should determine the position performance for that role' do
          post action, params: params
          expect(speech).to eq 'Hero man has played Tristana Adc two times and averages 2.0 kills.'
        end
      end

      context 'with no role specified' do
        before :each do
          summoner_params[:role] = ''
        end

        context 'with one role' do
          it 'should determine the position performance for the one role' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana Adc two times and averages 2.0 kills.'
          end
        end

        context 'with multiple roles' do
          before :each do
            @match2.summoner_performances.first.update(role: 'DUO_SUPPORT')
          end

          it 'should indicate the value is aggregated across muliples roles' do
            post action, params: params
            expect(speech).to eq 'Hero man has played Tristana across Adc and Support two times and averages 2.0 kills.'
          end
        end
      end
    end
  end
end
