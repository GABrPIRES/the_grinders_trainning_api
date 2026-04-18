# config/routes.rb
Rails.application.routes.draw do
  # Define um namespace para a API, versionando as rotas.
  # Isso gera URLs como /api/v1/recurso
  get "up" => "rails/health#show", as: :rails_health_check
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post 'signup', to: 'registrations#create'
        post 'verify_email', to: 'verifications#verify'
      end
      namespace :coach do
        resource :invite, only: [:show], controller: 'invites'
        put 'settings', to: 'invites#update' # <--- Add this line
        resources :approvals, only: [:index, :update]
      end
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
      resources :sections, only: [:update] do
        member do
          put :log  # Aluno registra actual_load, actual_rpe, feito durante execução
        end
      end
      resources :exercicios, only: [] do
        member do
          put :log  # Aluno registra observation do exercício (granularidade por exercício)
        end
      end
      resources :alunos do
        resources :training_blocks, only: [:index, :create]
        member do
          post 'import_training_block', to: 'imports#create'
          post 'finalize_import', to: 'imports#finalize_import'
        end
      end
      resource :coach_dashboard, only: [:show], controller: :coach_dashboard
      resource :student_dashboard, only: [:show], controller: :student_dashboard
      resources :training_blocks, only: [:show, :update, :destroy] do
        resources :weeks, only: [:create]
      end
      resources :weeks, only: [:show, :update] do
        resources :treinos, only: [:index, :create]
        member do
          post :duplicate
          patch :toggle_feedback  # Coach ativa/desativa formulário semanal
        end
      end
      resources :treinos, only: [:show, :update, :destroy] do
        member do
          post :duplicate
          post :start    # Aluno inicia o treino → in_progress
          post :finish   # Aluno finaliza o treino → completed
          post :pause    # Aluno cancela início → volta para published
        end
      end

      # Formulário semanal
      resources :weekly_feedbacks, only: [:create] do
        collection do
          get :pending   # Retorna se há formulário pendente para o aluno logado
        end
      end
      post 'weekly_feedbacks/:week_id/snooze', to: 'weekly_feedbacks#snooze', as: :snooze_weekly_feedback

      # Notificações in-app
      resources :notifications, only: [:index] do
        member do
          post :read     # Marca notificação como lida
        end
      end

      # Dashboard do coach: revisão e aprovação de sugestões da IA
      namespace :coach do
        resources :invite, only: [] # mantém o namespace existente
        resources :treinos, only: [] do
          member do
            post :publish  # Toggle draft ↔ published (sem fluxo de IA)
            get  :review   # Retorna treino em draft com sugestões da IA por section + observação
            post :approve  # Coach aprova (com overrides opcionais) → publica o treino
          end
        end
        resources :weeks, only: [] do
          member do
            get  :review       # Retorna todos os treinos draft da semana com sugestões da IA
            post :approve_all  # Aprova todos os treinos draft da semana de uma vez
          end
        end
      end
    end
  end
end