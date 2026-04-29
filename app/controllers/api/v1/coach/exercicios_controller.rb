# app/controllers/api/v1/coach/exercicios_controller.rb
class Api::V1::Coach::ExerciciosController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin_or_coach!
  before_action :set_and_authorize_exercicio

  # PATCH /api/v1/coach/exercicios/:id
  def update
    if @exercicio.update(exercicio_params)
      render json: {
        id: @exercicio.id,
        coach_comment: @exercicio.coach_comment,
        video_link: @exercicio.video_link
      }
    else
      render json: @exercicio.errors, status: :unprocessable_entity
    end
  end

  private

  def set_and_authorize_exercicio
    @exercicio = Exercicio.joins(treino: { week: { training_block: :personal } })
                          .where(training_blocks: { personal_id: @current_user.personal.id })
                          .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Exercício não encontrado ou acesso negado." }, status: :not_found
  end

  def exercicio_params
    params.require(:exercicio).permit(:coach_comment, :video_link)
  end
end
