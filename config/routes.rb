Rails.application.routes.draw do
  root 'visitors#index'
  resources :events
end
