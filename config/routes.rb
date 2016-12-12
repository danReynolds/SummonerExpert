Rails.application.routes.draw do
  get 'index' => 'api#index'
  root to: 'api#index'

  resources :conversation, only: [:create]
  resources :summoner, only: [:show]
end
