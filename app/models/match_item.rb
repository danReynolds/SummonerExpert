class MatchItem < ActiveRecord::Base
  belongs_to :summoner_performance

  validates_presence_of :summoner_performance_id, :item_id
end
