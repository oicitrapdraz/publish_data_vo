Rails.application.routes.draw do
  devise_for :admins
  root 'home#index'

  match 'publish/metadata', via: [:get, :post]

  get 'publish/parse_match'

  get 'publish/first_check'

  get 'publish/rd'

  get 'publish/final_check'
end
