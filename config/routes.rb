Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post '/encode', to: 'short_urls#encode'
  post '/decode', to: 'short_urls#decode'
  get '/:short_code', to: 'short_urls#redirect'
end
