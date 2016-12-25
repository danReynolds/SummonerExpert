Rails.application.routes.draw do
  root to: 'application#status'

  namespace :champions do
    post :title
    post :description
    post :ally_tips
    post :enemy_tips
    post :ability
    post :cooldown
    post :lane
    post :build
    post :ability_order
    post :counters
    post :matchup
  end
end
