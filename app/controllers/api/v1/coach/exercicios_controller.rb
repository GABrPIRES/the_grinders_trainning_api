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

  # PATCH /api/v1/coach/exercicios/:id/move_up
  # Faz swap de position com o vizinho imediatamente acima dentro do mesmo treino.
  # No-op (200) se já é o primeiro.
  def move_up
    swap_with(neighbor_above)
    render_ordered_list
  end

  # PATCH /api/v1/coach/exercicios/:id/move_down
  def move_down
    swap_with(neighbor_below)
    render_ordered_list
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

  def neighbor_above
    @exercicio.treino.exercicios
              .where("position < ?", @exercicio.position)
              .order(position: :desc)
              .first
  end

  def neighbor_below
    @exercicio.treino.exercicios
              .where("position > ?", @exercicio.position)
              .order(position: :asc)
              .first
  end

  # Swap atômico: usa Time.current como buffer para evitar conflito do
  # index único futuro (se vier a existir). Aqui não temos unique index, mas
  # mantemos a transação para coerência.
  def swap_with(other)
    return unless other
    Exercicio.transaction do
      cur = @exercicio.position
      nxt = other.position
      @exercicio.update_column(:position, nxt)
      other.update_column(:position, cur)
    end
  end

  def render_ordered_list
    exercicios = @exercicio.treino.reload.exercicios.order(:position, :created_at)
    render json: exercicios.map { |e| { id: e.id, name: e.name, position: e.position } }
  end
end
