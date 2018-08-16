Rails.application.routes.draw do
  root 'home#index'

  # Devise URLs

  devise_for :admins

  # Publish URLs

  match 'publish/create_publish_request', via: [:get, :post]
  match 'publish/metadata', via: [:get, :post]
  match 'publish/parse_match', via: [:get, :post]
  match 'publish/select_data', via: [:get, :post]

  get 'publish/first_check'
  get 'publish/accepted'
  get 'publish/end'

  match 'publish/generate_rd', via: [:get, :post]

  post 'publish/imp_q'

  # DataProduct URLs

  get 'data_product/show'
  get 'data_product/edit_metadata'

  post 'data_product/update_metadata'

  get 'data_product/edit_columns'

  post 'data_product/update_columns'
  post 'data_product/accept'
  post 'data_product/revoke'
end
