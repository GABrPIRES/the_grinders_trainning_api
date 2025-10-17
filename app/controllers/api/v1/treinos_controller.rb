# app/controllers/api/v1/treinos_controller.rb
class Api::V1::TreinosController < ApplicationController
    before_action :authenticate_request
    before_action :authorize_admin_or_coach!
    before_action :set_week, only: [:index, :create]
    before_action :set_treino, only: [:show, :update, :destroy, :duplicate]
  
    # GET /api/v1/weeks/:week_id/treinos
    def index
        # ATUALIZAÇÃO: Busca treinos aninhados na semana
        @treinos = @week.treinos.order(day: :asc)
        render json: @treinos.as_json(include: :exercicios)
    end
  
    # GET /api/v1/treinos/:id
    def show
      render json: @treino, include: { exercicios: { include: :sections } }
    end
  
    # POST /api/v1/weeks/:week_id/treinos
    def create
        @treino = @week.treinos.build(treino_params)
        @treino.personal_id = @week.training_block.personal_id
      
        # NOVA VALIDAÇÃO
        treino_day = @treino.day.to_date
        if @week.start_date.present? && @week.end_date.present?
          unless treino_day.between?(@week.start_date, @week.end_date)
            return render json: { errors: ["A data do treino (#{treino_day.strftime('%d/%m/%Y')}) está fora do período da semana (#{@week.start_date.strftime('%d/%m/%Y')} - #{@week.end_date.strftime('%d/%m/%Y')})."] }, status: :unprocessable_entity
          end
        end
      
        if @treino.save
          render json: @treino, include: { exercicios: { include: :sections } }, status: :created
        else
          render json: @treino.errors, status: :unprocessable_entity
        end
      end
  
    # PATCH/PUT /api/v1/treinos/:id
    def update
      if @treino.update(treino_params)
        render json: @treino
      else
        render json: @treino.errors, status: :unprocessable_entity
      end
    end
  
    # DELETE /api/v1/treinos/:id
    def destroy
      @treino.destroy
      render json: { message: 'Treino deletado com sucesso' }, status: :ok
    end

    # POST /api/v1/treinos/:id/duplicate
    def duplicate
        # O @treino (treino de origem) já é carregado pelo before_action set_treino
        destination_week = Week.joins(training_block: :personal)
                               .where(training_blocks: { personal_id: @current_user.personal.id })
                               .find(duplication_params[:week_id])
  
        new_treino = nil # Define a variável fora da transação
  
        Treino.transaction do
          # Cria o novo treino com os dados recebidos e alguns dados do original
          new_treino = destination_week.treinos.create!(
            name: duplication_params[:name],
            day: duplication_params[:day],
            personal_id: @treino.personal_id
          )
  
          # Valida se a data está dentro do intervalo da semana de destino
          new_day = new_treino.day.to_date
          if destination_week.start_date.present? && destination_week.end_date.present?
            unless new_day.between?(destination_week.start_date, destination_week.end_date)
              # Se a validação falhar, reverte toda a transação
              raise ActiveRecord::Rollback, "A data do novo treino está fora do período da semana de destino."
            end
          end
  
          # Copia cada exercício e suas respectivas seções
          @treino.exercicios.includes(:sections).each do |source_exercicio|
            new_exercicio = new_treino.exercicios.create!(name: source_exercicio.name)
            source_exercicio.sections.each do |source_section|
              new_attributes = source_section.attributes.except("id", "exercicio_id", "created_at", "updated_at")
              new_attributes["feito"] = false # Zera o status de "feito"
              new_exercicio.sections.create!(new_attributes)
            end
          end
        end
  
        render json: new_treino, include: { exercicios: { include: :sections } }, status: :created
  
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Treino original ou semana de destino não encontrada.' }, status: :not_found
      rescue ActiveRecord::Rollback => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end
  
    private

    def set_week
      # Garante que o coach possa acessar a semana
      @week = Week.joins(training_block: :personal)
                  .where(training_blocks: { personal_id: @current_user.personal.id })
                  .find(params[:week_id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Semana não encontrada.' }, status: :not_found
    end
  
    def set_treino
      # Esta lógica continua a mesma, pois o treino ainda tem um personal_id
      @treino = @current_user.personal.treinos.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Treino não encontrado' }, status: :not_found
    end
  
    def treino_params
      # ATUALIZAÇÃO: Removemos aluno_id, pois ele não existe mais no treino
      params.require(:treino).permit(
        :name,
        :day,
        exercicios_attributes: [
          :id, 
          :name, 
          :_destroy, 
          sections_attributes: [
            :id, 
            :carga, 
            :series, 
            :reps, 
            :equip, 
            :rpe, 
            :pr, 
            :feito, 
            :_destroy
          ]
        ]
      )
    end

    def duplication_params
        params.require(:duplication).permit(:week_id, :name, :day)
    end
  end