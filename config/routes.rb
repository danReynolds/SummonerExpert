Rails.application.routes.draw do
  match '/', to: 'api#index', via: :post

  namespace :champions do
    post :title
  end
end
