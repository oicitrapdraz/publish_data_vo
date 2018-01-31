Rails.application.routes.draw do
  get 'publish/metadata'

  get 'publish/parse_match'

  get 'publish/first_check'

  get 'publish/rd'

  get 'publish/final_check'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
