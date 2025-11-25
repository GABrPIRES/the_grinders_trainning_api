# app/controllers/api/v1/meus_treinos_controller.rb
class Api::V1::MeusTreinosController < ApplicationController
  before_action :authenticate_request
  before_action :set_aluno_profile

  # GET /api/v1/meus_treinos
  # Agora retorna os Blocos de Treino, não apenas treinos soltos
  def index
    # Busca os blocos ordenados pelo mais recente (o atual)
    @training_blocks = @aluno_profile.training_blocks
                                     .order(start_date: :desc, created_at: :desc)
    
    # Inclui as semanas e os treinos (sem os exercícios para ficar leve)
    render json: @training_blocks, include: { 
      weeks: { 
        include: :treinos 
      } 
    }
  end

  # GET /api/v1/meus_treinos/:id
  def show
    # Precisamos encontrar o treino através das associações:
    # Aluno -> TrainingBlock -> Week -> Treino
    @treino = Treino.joins(week: { training_block: :aluno })
                    .where(alunos: { id: @aluno_profile.id })
                    .find(params[:id])

    render json: @treino, include: { exercicios: { include: :sections } }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Treino não encontrado ou não pertence a este aluno.' }, status: :not_found
  end

  private

  def set_aluno_profile
    @aluno_profile = @current_user.aluno
    if @aluno_profile.nil?
      render json: { error: 'Perfil de aluno não encontrado para este usuário.' }, status: :not_found
    end
  end
end