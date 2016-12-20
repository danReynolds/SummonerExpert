Rails.application.routes.draw do
  match '/', to: 'api#index', via: :post

  namespace :champions do
    post :title
    post :description
    post :ally_tips
    post :enemy_tips
    post :ability
    post :cooldown
    post :lane
    post :build
    post :matchup
  end
end
