# config/routes.rb
Rails.application.routes.draw do
  # Define um namespace para a API, versionando as rotas.
  # Isso gera URLs como /api/v1/recurso
  namespace :api do
    namespace :v1 do
      # Cria a rota POST /api/v1/users que aponta para a action 'create' do UsersController
      resources :users, only: [:create, :destroy]
      post 'login', to: 'sessions#create'
      resource :profile, only: [:show, :update], controller: :profile
      resources :treinos
      resources :alunos, only: [:index, :show, :create, :update, :destroy]
      resources :planos
      resources :assinaturas, only: [:index, :show, :create, :destroy]
      namespace :admin do
        resources :alunos, only: [:create, :index, :show, :update, :destroy]
      end
      get 'meus_treinos', to: 'meus_treinos#index'
      get 'meus_treinos/:id', to: 'meus_treinos#show'
    end
  end
end