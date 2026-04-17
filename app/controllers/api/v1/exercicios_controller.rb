# app/controllers/api/v1/exercicios_controller.rb
class Api::V1::ExerciciosController < ApplicationController
  before_action :authenticate_request
  before_action :set_and_authorize_exercicio

  # PUT /api/v1/exercicios/:id/log
  # Aluno registra a observation do exercício (uma por exercício, não por série).
  def log
    treino = @exercicio.treino

    unless treino.in_progress? || treino.completed?
      return render json: { error: "O treino não está em andamento ou concluído." }, status: :unprocessable_entity
    end

    week = treino.week
    if treino.completed? && week.weekly_feedbacks.exists?(aluno: @current_user.aluno)
      return render json: { error: "Não é possível editar após enviar o formulário semanal." },
                    status: :unprocessable_entity
    end

    if @exercicio.update(observation: params.dig(:exercicio, :observation))
      render json: { id: @exercicio.id, observation: @exercicio.observation }
    else
      render json: @exercicio.errors, status: :unprocessable_entity
    end
  end

  private

  def set_and_authorize_exercicio
    @exercicio = Exercicio.find(params[:id])
    aluno_do_treino = @exercicio.treino.week.training_block.aluno

    unless @current_user.aluno && @current_user.aluno.id == aluno_do_treino.id
      render json: { error: "Não autorizado. Este exercício não pertence a você." }, status: :unauthorized
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Exercício não encontrado" }, status: :not_found
  end
end
