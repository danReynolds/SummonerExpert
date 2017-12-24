require 'sidekiq/web'
# https://github.com/mperham/sidekiq/wiki/Monitoring#forbidden

Rails.application.routes.draw do
  Sidekiq::Web.set :session_secret, Rails.application.secrets[:secret_key_base]
  mount Sidekiq::Web => '/sidekiq'

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
    post :performance_summary
    post :champion_performance_summary
    post :champion_performance_position
    post :champion_performance_ranking
    post :champion_counters
    post :champion_build
    post :champion_bans
    post :champion_spells
    post :champion_matchups
  end
end
