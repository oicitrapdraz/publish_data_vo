Rails.application.routes.draw do
  root 'home#index'

  devise_for :admins

  match 'publish/metadata', via: [:get, :post]

  get 'publish/parse_match'

  get 'publish/first_check'

  get 'publish/accepted'

  match 'publish/generate_rd', via: [:get, :post]

  get 'publish/final_check'

  get 'data_product/show'

  post 'data_product/accept'

  post 'data_product/revoke'
end
