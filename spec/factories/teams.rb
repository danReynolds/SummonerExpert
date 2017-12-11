FactoryBot.define do
  factory :team do
    sequence(:team_id) { |n| n }
    tower_kills 2
    inhibitor_kills 3
    baron_kills 1
    dragon_kills 2
    riftherald_kills 1
  end
end
