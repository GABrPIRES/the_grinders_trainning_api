class Api::V1::Coach::InvitesController < ApplicationController
    before_action :authenticate_request

    # GET /api/v1/coach/invite
    def show
        return render json: { error: 'Acesso negado' }, status: :forbidden unless @current_user.personal?

        personal = @current_user.personal
        code = personal.active_signup_code
        
        base_url = ENV.fetch('FRONTEND_URL', 'http://localhost:3001') 
        invite_link = "#{base_url}/signup?coachCode=#{code}"

        render json: {
        code: code,
        link: invite_link,
        expires_at: personal.signup_code_expires_at,
        auto_approve: personal.auto_approve_students # Used by frontend toggle
        }
    end

    # PUT /api/v1/coach/settings
    def update
        return render json: { error: 'Acesso negado' }, status: :forbidden unless @current_user.personal?
        
        personal = @current_user.personal

        # Updates the auto-approval boolean
        if personal.update(settings_params)
        render json: { 
            message: 'Configurações atualizadas com sucesso',
            auto_approve: personal.auto_approve_students
        }
        else
        render json: { error: 'Erro ao atualizar configurações' }, status: :unprocessable_entity
        end
    end

    private

    def settings_params
        params.require(:invite).permit(:auto_approve_students)
    rescue ActionController::ParameterMissing
        # Fallback if frontend sends directly without wrapping (e.g., { auto_approve_students: true })
        params.permit(:auto_approve_students)
    end
end