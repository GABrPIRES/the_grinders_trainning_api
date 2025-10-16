# config/routes.rb
Rails.application.routes.draw do
  # Define um namespace para a API, versionando as rotas.
  # Isso gera URLs como /api/v1/recurso
  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :destroy, :index, :show, :update]
      post 'login', to: 'sessions#create'
      resource :profile, only: [:show, :update], controller: :profile do
        post 'change_password', on: :collection
      end
      resources :alunos, only: [:index, :show, :create, :update, :destroy]
      resources :planos
      resources :assinaturas, only: [:index, :show, :create, :destroy]
      resources :payment_methods, only: [:index, :create, :destroy]
      resources :pagamentos, only: [:index, :create, :update, :destroy, :show]
      namespace :admin do
        resources :alunos, only: [:create, :index, :show, :update, :destroy]
        resources :coaches, only: [:index]
        resources :planos, only: [:index]
      end
      get 'meus_treinos', to: 'meus_treinos#index'
      get 'meus_treinos/:id', to: 'meus_treinos#show'
      resource :meu_coach, only: [:show], controller: 'meu_coach'
      resource :minha_assinatura, only: [:show], controller: 'minha_assinatura'
      resources :sections, only: [:update]
      resources :alunos do
        resources :training_blocks, only: [:index, :create]
      end
      resources :training_blocks, only: [:show, :update, :destroy]
      resources :weeks, only: [:show] do
        resources :treinos, only: [:index, :create]
      end
      resources :treinos, only: [:show, :update, :destroy]
    end
  end
end