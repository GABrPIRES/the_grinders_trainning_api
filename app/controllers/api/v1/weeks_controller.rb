# app/controllers/api/v1/weeks_controller.rb
class Api::V1::WeeksController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_coach!
    before_action :set_week
  
    # GET /api/v1/weeks/:id
    def show
      # CORREÇÃO AQUI: Incluímos os :exercicios de cada treino
      render json: @week, include: { treinos: { include: :exercicios } }
    end
  
    # PATCH/PUT /api/v1/weeks/:id
    def update
      if @week.update(week_params)
        render json: @week
      else
        render json: @week.errors, status: :unprocessable_entity
      end
    end
  
    private
  
    def set_week
      @week = Week.joins(training_block: :personal)
                  .where(training_blocks: { personal_id: @current_user.personal.id })
                  .find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Semana não encontrada ou não pertence a este coach.' }, status: :not_found
    end
  
    def week_params
      params.require(:week).permit(:start_date, :end_date, :week_number)
    end
  
    def authorize_coach!
      return if @current_user.personal?
      render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
    end
  end