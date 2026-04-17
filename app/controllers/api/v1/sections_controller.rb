# app/controllers/api/v1/sections_controller.rb
class Api::V1::SectionsController < ApplicationController
  before_action :authenticate_request
  before_action :set_and_authorize_section

  # PATCH/PUT /api/v1/sections/:id
  def update
    if section_params[:rpe].present? && section_params[:rpe].to_f < 5
      return render json: { error: "O RPE deve ser maior ou igual a 5." }, status: :unprocessable_entity
    end

    if @section.update(section_params)
      render json: @section
    else
      render json: @section.errors, status: :unprocessable_entity
    end
  end

  # PUT /api/v1/sections/:id/log
  # Aluno registra carga real, RPE real e feito durante a execução ativa do treino.
  def log
    treino = @section.exercicio.treino

    unless treino.in_progress? || treino.completed?
      return render json: { error: "O treino não está em andamento ou concluído." }, status: :unprocessable_entity
    end

    # Bloqueia edição se o aluno já enviou o formulário semanal desta semana.
    week = treino.week
    if treino.completed? && week.weekly_feedbacks.exists?(aluno: @current_user.aluno)
      return render json: { error: "Não é possível editar após enviar o formulário semanal." },
                    status: :unprocessable_entity
    end

    if @section.update(log_params)
      render json: @section
    else
      render json: @section.errors, status: :unprocessable_entity
    end
  end

  private

  def set_and_authorize_section
    @section = Section.find(params[:id])
    aluno_do_treino = @section.exercicio.treino.week.training_block.aluno

    unless @current_user.aluno && @current_user.aluno.id == aluno_do_treino.id
      render json: { error: "Não autorizado. Esta seção não pertence a você." }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Seção não encontrada" }, status: :not_found
  end

  def section_params
    params.require(:section).permit(:feito, :rpe, :pr)
  end

  def log_params
    params.require(:section).permit(:actual_load, :actual_rpe, :feito)
  end
end
