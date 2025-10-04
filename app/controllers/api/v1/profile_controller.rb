# app/controllers/api/v1/profile_controller.rb
class Api::V1::ProfileController < ApplicationController
    before_action :authenticate_request
  
    # GET /api/v1/profile
    def show
      # Incluímos os perfis associados para uma resposta mais completa
      render json: @current_user.as_json(
        except: :password_digest, 
        include: [:personal, :aluno]
      )
    end
  
    # PATCH/PUT /api/v1/profile
    def update
      # Inicia com os parâmetros básicos do User
      user_params = profile_user_params
      # Filtra a senha se ela não for enviada
      user_params.delete_if { |k, v| k.include?('password') && v.blank? }
  
      # Começa a transação para garantir que tudo seja salvo ou nada
      ActiveRecord::Base.transaction do
        @current_user.update!(user_params)
  
        # Atualiza o perfil específico dependendo da role
        if @current_user.personal?
          @current_user.personal.update!(profile_personal_params)
        elsif @current_user.aluno?
          @current_user.aluno.update!(profile_aluno_params)
        end
      end
  
      render json: @current_user.as_json(except: :password_digest, include: [:personal, :aluno]), status: :ok
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    # POST /api/v1/profile/change_password
    def change_password
        # Verifica se a senha atual fornecida está correta
        unless @current_user.authenticate(params[:current_password])
        render json: { error: 'Senha atual incorreta' }, status: :unauthorized
        return
        end

        # Tenta atualizar a senha com a nova
        if @current_user.update(password: params[:new_password], password_confirmation: params[:password_confirmation])
        render json: { message: 'Senha alterada com sucesso!' }, status: :ok
        else
        render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
        end
    end
  
    private
  
    # Parâmetros permitidos para o modelo User (todos podem alterar)
    def profile_user_params
      params.require(:profile).permit(:name, :email, :password, :password_confirmation)
    end
  
    # Parâmetros permitidos apenas para o perfil Personal (Coach)
    def profile_personal_params
      params.require(:profile).permit(:bio, :phone_number, :instagram)
    end
  
    # Parâmetros permitidos apenas para o perfil Aluno
    def profile_aluno_params
      params.require(:profile).permit(
        :phone_number, :birth_date, :weight, :height, :lesao, :restricao_medica,
        :objetivo, :treinos_semana, :tempo_treino, :horario_treino, :pr_supino,
        :pr_terra, :pr_agachamento, :new_pr_supino, :new_pr_terra, :new_pr_agachamento
      )
    end
  end