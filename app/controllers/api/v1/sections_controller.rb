# app/controllers/api/v1/sections_controller.rb
class Api::V1::SectionsController < ApplicationController
  before_action :authenticate_request
  before_action :set_and_authorize_section

  # PATCH/PUT /api/v1/sections/:id
  def update
    # Validar RPE se ele estiver presente nos parâmetros
    if section_params[:rpe].present?
      rpe_value = section_params[:rpe].to_f
      if rpe_value < 5
        return render json: { error: "O RPE deve ser maior ou igual a 5." }, status: :unprocessable_entity
      end
    end

    if @section.update(section_params)
      render json: @section
    else
      render json: @section.errors, status: :unprocessable_entity
    end
  end

  private

  def set_and_authorize_section
    @section = Section.find(params[:id])
    
    # Nova lógica de segurança para a estrutura de Blocos:
    # Aluno -> TrainingBlock -> Week -> Treino -> Exercicio -> Section
    # Verifica se o aluno logado é o dono do TrainingBlock desta section
    
    aluno_do_treino = @section.exercicio.treino.week.training_block.aluno
    
    unless @current_user.aluno && @current_user.aluno.id == aluno_do_treino.id
      render json: { error: 'Não autorizado. Esta seção não pertence a você.' }, status: :unauthorized
    end

  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Seção não encontrada' }, status: :not_found
  end

  def section_params
    params.require(:section).permit(:feito, :rpe, :pr)
  end
end