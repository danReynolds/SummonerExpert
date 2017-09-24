Rails.application.routes.draw do
  root to: 'application#status'
  post :patch, to: 'application#patch'
  post :reset, to: 'application#reset'

  namespace :champions do
    post :title
    post :ally_tips
    post :enemy_tips
    post :ability
    post :cooldown
    post :role_performance_summary
    post :role_performance
    post :build
    post :ability_order
    post :counters
    post :matchup
    post :ranking
    post :stats
    post :lore
    post :matchup_ranking
  end

  namespace :items do
    post :description
    post :build
  end

  namespace :summoners do
    post :show
  end
end
