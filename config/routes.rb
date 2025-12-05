# config/routes.rb
Rails.application.routes.draw do
  # Define um namespace para a API, versionando as rotas.
  # Isso gera URLs como /api/v1/recurso
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :v1 do
      get "student_dashboard/show"
      get "coach_dashboard/show"
      get "imports/create"
      resources :users, only: [:create, :destroy, :index, :show, :update]
      post 'login', to: 'sessions#create'
      delete 'logout', to: 'sessions#destroy'
      post 'auth/change_password', to: 'profile#change_password'
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
        member do
          post 'import_training_block', to: 'imports#create'
          post 'finalize_import', to: 'imports#finalize_import'
        end
      end
      resource :coach_dashboard, only: [:show], controller: :coach_dashboard
      resource :student_dashboard, only: [:show], controller: :student_dashboard
      resources :training_blocks, only: [:show, :update, :destroy]
      resources :weeks, only: [:show] do
        resources :treinos, only: [:index, :create]
      end
      resources :treinos, only: [:show, :update, :destroy]
      resources :treinos, only: [:show, :update, :destroy] do
        member do
          post :duplicate
        end
      end
    end
  end
end