FactoryBot.define do
  factory :summoner do
    sequence(:summoner_id)
    sequence(:name) { |n| "summoner_#{n}" }
    region 'NA1'
  end
end
