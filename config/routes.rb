# config/routes.rb
Rails.application.routes.draw do
  # Define um namespace para a API, versionando as rotas.
  # Isso gera URLs como /api/v1/recurso
  namespace :api do
    namespace :v1 do
      # Cria a rota POST /api/v1/users que aponta para a action 'create' do UsersController
      resources :users, only: [:create]
      post 'login', to: 'sessions#create'
      resource :profile, only: [:show], controller: :profile
      resources :treinos
    end
  end
end