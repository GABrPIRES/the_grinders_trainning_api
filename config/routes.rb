# config/routes.rb
Rails.application.routes.draw do
  # Define um namespace para a API, versionando as rotas.
  # Isso gera URLs como /api/v1/recurso
  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :destroy, :index, :show, :update]
      post 'login', to: 'sessions#create'
      resource :profile, only: [:show, :update], controller: :profile
      resources :treinos
      resources :alunos, only: [:index, :show, :create, :update, :destroy]
      resources :planos
      resources :assinaturas, only: [:index, :show, :create, :destroy]
      namespace :admin do
        resources :alunos, only: [:create, :index, :show, :update, :destroy]
        resources :coaches, only: [:index]
      end
      get 'meus_treinos', to: 'meus_treinos#index'
      get 'meus_treinos/:id', to: 'meus_treinos#show'
    end
  end
end