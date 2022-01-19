Rails.application.routes.draw do
  get '/health', to: 'application#health_check'
  resources :random_strings
  post 'jobs', to: 'jobs#create'
end
