class Api::V1::Auth::RegistrationsController < ApplicationController
    # skip_before_action :authenticate_request, only: [:create] # Assumindo que você tem um before_action padrão

    def create
      # 1. Validar código do coach
      personal = Personal.where(signup_code: params[:coach_code])
                         .where('signup_code_expires_at > ?', Time.current)
                         .first

      return render json: { error: 'Código de convite inválido ou expirado' }, status: :bad_request unless personal

      ActiveRecord::Base.transaction do
        # 2. Criar Usuário (Unverified)
        @user = User.new(user_params)
        @user.role = :aluno
        @user.status = :unverified
        @user.save!

        # 3. Criar Perfil de Aluno vinculado ao Personal
        Aluno.create!(
          user: @user,
          personal: personal,
          phone_number: params[:phone_number]
        )

        # 4. Enviar e-mail (usando deliver_now para simplicidade, idealmente deliver_later com background job)
        AuthMailer.verify_email(@user).deliver_now
      end

      render json: { message: 'Cadastro realizado! Verifique seu e-mail.' }, status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end