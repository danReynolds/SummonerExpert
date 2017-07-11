Rails.application.routes.draw do
  root to: 'application#status'

  get '/.well-known/acme-challenge/D_yF14gneIiGzMult-n_VaGxi8BvPpNsrhtK_eFBZwc' => 'application#letsencrypt'

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
    post :ranking
    post :stats
  end

  namespace :items do
    post :show
  end

  namespace :summoners do
    post :show
    post :champion
  end
end
