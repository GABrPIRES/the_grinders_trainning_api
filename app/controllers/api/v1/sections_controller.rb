# app/controllers/api/v1/sections_controller.rb
class Api::V1::SectionsController < ApplicationController
    before_action :authenticate_request
    before_action :set_and_authorize_section
  
    # PATCH/PUT /api/v1/sections/:id
    def update
      # CORREÇÃO: Removemos o cálculo de PR do backend.
      # A API agora simplesmente salva os dados que o frontend envia.
      if @section.update(section_params)
        render json: @section
      else
        render json: @section.errors, status: :unprocessable_entity
      end
    end
  
    private
  
    def set_and_authorize_section
      @section = Section.find(params[:id])
      # Segurança: Garante que a section pertence a um treino do aluno logado
      aluno_profile = @current_user.aluno
      unless aluno_profile && @section.exercicio.treino.aluno_id == aluno_profile.id
        render json: { error: 'Não autorizado' }, status: :unauthorized
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Seção não encontrada' }, status: :not_found
    end
  
    def section_params
      # CORREÇÃO: Adicionamos :pr aos parâmetros permitidos.
      params.require(:section).permit(:feito, :rpe, :pr)
    end
  end