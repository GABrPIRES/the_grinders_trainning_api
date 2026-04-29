# app/controllers/api/v1/coach/exercise_models_controller.rb
class Api::V1::Coach::ExerciseModelsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_admin_or_coach!
  before_action :set_model, only: [:update, :destroy]

  # GET /api/v1/coach/exercise_models
  def index
    models = @current_user.personal.exercise_models.order(name: :asc)
    render json: models.map(&:as_summary_json)
  end

  # POST /api/v1/coach/exercise_models
  def create
    model = @current_user.personal.exercise_models.build(exercise_model_params)
    if model.save
      render json: model.as_summary_json, status: :created
    else
      render json: model.errors, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/coach/exercise_models/:id
  def update
    if @model.update(exercise_model_params)
      render json: @model.as_summary_json
    else
      render json: @model.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/coach/exercise_models/:id
  def destroy
    @model.destroy
    head :no_content
  end

  private

  def set_model
    @model = @current_user.personal.exercise_models.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Modelo não encontrado." }, status: :not_found
  end

  def exercise_model_params
    params.require(:exercise_model).permit(
      :name, :exercise_name, :load, :load_unit,
      :series, :reps, :rpe, :coach_comment, :video_link
    )
  end
end
