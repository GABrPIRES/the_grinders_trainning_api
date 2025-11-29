# app/controllers/api/v1/admin/coaches_controller.rb
class Api::V1::Admin::CoachesController < ApplicationController
    before_action :authenticate_request
    before_action :check_if_admin
  
    # GET /api/v1/admin/coaches
    def index
      # 1. Base da query com Eager Loading para evitar N+1
      scope = Personal.includes(:user, :alunos)
  
      # 2. Filtro de Busca (Nome ou Email)
      if params[:search].present?
        term = "%#{params[:search].downcase}%"
        scope = scope.joins(:user).where("lower(users.name) LIKE ? OR lower(users.email) LIKE ?", term, term)
      end
  
      # 3. Paginação
      page = (params[:page] || 1).to_i
      limit = (params[:limit] || 10).to_i
      offset = (page - 1) * limit
  
      # Contagem total para o frontend saber quantas páginas existem
      total_coaches = scope.count
      
      # Busca os registros paginados
      coaches = scope.order('users.created_at DESC').limit(limit).offset(offset)
  
      # 4. Montagem do JSON no formato que o Frontend espera
      coaches_data = coaches.map do |coach|
        {
          id: coach.id,
          user_id: coach.user.id,
          phone_number: coach.phone_number,
          created_at: coach.created_at,
          user: {
            name: coach.user.name,
            email: coach.user.email,
            status: coach.user.status
          },
          # Contagem real de alunos deste coach
          alunos_count: coach.alunos.count
        }
      end
  
      # Retorna o objeto { coaches, total }
      render json: { coaches: coaches_data, total: total_coaches }
    end
  
    private
  
    def check_if_admin
      unless @current_user.admin?
        render json: { error: 'Acesso não autorizado' }, status: :forbidden
      end
    end
  end