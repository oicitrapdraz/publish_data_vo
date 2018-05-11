Rails.application.routes.draw do
  root 'home#index'

  get 'home/example'

  devise_for :admins

  match 'publish/create_publish_request', via: [:get, :post]
  match 'publish/metadata', via: [:get, :post]
  get 'publish/parse_match/:id' => 'publish#parse_match'
  post 'publish/parse_match'
  get 'publish/first_check'
  get 'publish/accepted'
  get 'publish/end'
  match 'publish/generate_rd', via: [:get, :post]
  post 'publish/imp_q'

  get 'data_product/show'
  get 'data_product/edit_metadata'
  post 'data_product/update_metadata'
  get 'data_product/edit_columns'
  post 'data_product/update_columns'
  post 'data_product/accept'
  post 'data_product/revoke'
end
