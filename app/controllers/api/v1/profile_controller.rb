# app/controllers/api/v1/profile_controller.rb
class Api::V1::ProfileController < ApplicationController
  before_action :authenticate_request

  # GET /api/v1/profile
  def show
    # Montamos a resposta manualmente para garantir a estrutura correta no JSON
    response = {
      id: @current_user.id,
      name: @current_user.name,
      email: @current_user.email,
      role: @current_user.role,
      created_at: @current_user.created_at,
      updated_at: @current_user.updated_at
    }

    # Se for ALUNO, anexa dados do aluno
    if @current_user.aluno
      response[:aluno] = @current_user.aluno.as_json(
        except: [:created_at, :updated_at, :user_id, :personal_id]
      )
    end

    # Se for PERSONAL (Coach), anexa dados do personal
    if @current_user.personal
      response[:personal] = @current_user.personal.as_json(
        except: [:created_at, :updated_at, :user_id]
      )
      # Se quiser incluir métodos de pagamento também:
      response[:personal][:payment_methods] = @current_user.personal.payment_methods.as_json
    end

    render json: response
  end

  # PUT /api/v1/profile
  def update
    ActiveRecord::Base.transaction do
      # 1. Atualiza dados do Usuário (se enviado)
      if params[:user].present?
        @current_user.update!(user_update_params)
      end

      # 2. Atualiza dados de Aluno (se o usuário for aluno e enviou dados)
      if @current_user.aluno && params[:aluno].present?
        @current_user.aluno.update!(aluno_update_params)
      end

      # 3. Atualiza dados de Personal/Coach (se o usuário for coach e enviou dados)
      if @current_user.personal && params[:personal].present?
        @current_user.personal.update!(personal_update_params)
      end
    end

    # Retorna os dados atualizados chamando o método 'show'
    show
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  # POST /api/v1/auth/change_password
  def change_password
    unless @current_user.authenticate(params[:current_password])
      return render json: { error: 'Senha atual incorreta' }, status: :unauthorized
    end

    if @current_user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      render json: { message: 'Senha alterada com sucesso!' }, status: :ok
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # --- Strong Parameters ---

  def user_update_params
    # Permite atualizar apenas o nome (email geralmente é fixo ou requer fluxo específico)
    params.require(:user).permit(:name)
  end

  def aluno_update_params
    params.require(:aluno).permit(
      :phone_number, :birth_date, :weight, :height, 
      :objetivo, :lesao, :restricao_medica, 
      :treinos_semana, :tempo_treino, :horario_treino,
      :pr_supino, :pr_terra, :pr_agachamento, :new_pr_supino, 
      :new_pr_terra, :new_pr_agachamento
    )
  end

  def personal_update_params
    params.require(:personal).permit(
      :phone_number, :cref, :bio, 
      # Dados bancários e PIX (se estiverem na tabela personals)
      :bank_name, :bank_agency, :bank_account, :pix_key_1, :pix_key_2
    )
  end
end