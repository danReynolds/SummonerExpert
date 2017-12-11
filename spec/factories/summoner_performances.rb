FactoryBot.define do
  factory :summoner_performance do
    champion_id 45
    spell1_id 2
    spell2_id 3
    kills 2
    deaths 3
    assists 7
    role 'DUO_SUPPORT'
    largest_killing_spree 4
    total_killing_sprees 1
    double_kills 3
    triple_kills 2
    quadra_kills 1
    penta_kills 0
    total_damage_dealt 30000
    magic_damage_dealt 10000
    physical_damage_dealt 15000
    true_damage_dealt 1000
    largest_critical_strike 1000
    total_damage_dealt_to_champions 30000
    magic_damage_dealt_to_champions 15000
    physical_damage_dealt_to_champions 10000
    true_damage_dealt_to_champions 20000
    total_healing_done 10000
    vision_score 10
    cc_score 20
    gold_earned 25000
    turrets_killed 3
    inhibitors_killed 1
    total_minions_killed 250
    vision_wards_bought 10
    sight_wards_bought 20
    wards_placed 30
    wards_killed 10
    neutral_minions_killed 100
    neutral_minions_killed_team_jungle 100
    neutral_minions_killed_enemy_jungle 100
    participant_id 3


    association :summoner
    association :ban
  end
end
