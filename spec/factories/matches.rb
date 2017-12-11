FactoryBot.define do
  factory :match do
    queue_id 420
    season_id 9
    region_id 'NA1'
    sequence(:game_id)

    game_duration 30000

    association :team1, factory: :team
    association :team2, factory: :team

    transient do
      summoner_performances_count 10
    end

    before(:create) do |match, evaluator|
      team1 = create(:team)
      team2 = create(:team)
      match.team1 = team1
      match.team2 = team2
      match.winning_team = team1
    end

    after(:create) do |match, evaluator|
      create_list(
        :summoner_performance,
        evaluator.summoner_performances_count / 2,
        match: match,
        team: match.team1
      )
      create_list(
        :summoner_performance,
        evaluator.summoner_performances_count / 2,
        match: match,
        team: match.team2
      )
    end
  end
end
