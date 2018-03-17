Rails.application.routes.draw do
  root 'home#index'

  devise_for :admins

  match 'publish/metadata', via: [:get, :post]

  get 'publish/parse_match/:id' => 'publish#parse_match'

  post 'publish/parse_match'

  get 'publish/first_check'

  get 'publish/accepted'

  get 'publish/end'

  match 'publish/generate_rd', via: [:get, :post]

  get 'publish/final_check'

  get 'data_product/show'

  post 'data_product/accept'

  post 'data_product/revoke'
end
