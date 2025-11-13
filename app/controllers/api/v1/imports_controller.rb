# app/controllers/api/v1/imports_controller.rb
require 'roo'

class Api::V1::ImportsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!
  before_action :set_aluno

  # POST /api/v1/alunos/:id/import_training_block
  def create
    files = params[:files]
    if files.blank? || !files.is_a?(Array)
      return render json: { errors: ["Nenhum arquivo enviado ou formato inválido."] }, status: :unprocessable_entity
    end
    if files.size > 5
       return render json: { errors: ["Você pode importar no máximo 5 arquivos por vez."] }, status: :unprocessable_entity
    end
    
    parsed_blocks_data = []
    errors = []

    files.each_with_index do |file, index|
      begin
        parsed_data = parse_spreadsheet(file)
        parsed_blocks_data.push(parsed_data)
      rescue StandardError => e
        errors.push("Erro ao processar o arquivo '#{file.original_filename}': #{e.message}")
        Rails.logger.error("Import Error for file #{file.original_filename}: #{e.message}\n#{e.backtrace.join("\n")}")
      end
    end
    
    if errors.present?
      render json: { errors: errors, parsed_data: parsed_blocks_data }, status: :partial_content
    else
      render json: { parsed_data: parsed_blocks_data }, status: :ok
    end
  end


  # POST /api/v1/alunos/:id/finalize_import
  def finalize_import
    errors = []
    created_blocks_count = 0
    
    begin
      target_block_id = params.require(:target_block_id)
      
      # Define os Strong Parameters (esta parte estava correta)
      permitted_params = params.require(:imported_data).map do |block_param|
        block_param.permit(
          :id, :block_title, :total_weeks, :week_number, :start_date, :end_date,
          treinos: [
            :id, :name, :day, :_destroy,
            exercicios: [
              :id, :name, :_destroy,
              sections: [
                :id, :carga, :load_unit, :series, :reps, :equip, :rpe, :pr, :feito, :_destroy
              ]
            ]
          ]
        )
      end
      imported_data = permitted_params

      # 1. Encontra o Bloco de Destino
      training_block = @aluno.training_blocks.find(target_block_id)

      ActiveRecord::Base.transaction do
        imported_data.each do |block_data_raw|
          
          # --- CORREÇÃO AQUI ---
          # Converte todas as chaves (ex: "treinos") para símbolos (ex: :treinos)
          block_data = block_data_raw.to_h.deep_symbolize_keys
          # --- FIM DA CORREÇÃO ---
          
          treinos_data = block_data.delete(:treinos) || []
          block_attributes = block_data.slice(:block_title, :total_weeks, :week_number, :start_date, :end_date)
          
          # NOTA: O 'training_block' já foi encontrado, então não precisamos mais
          # dos 'block_attributes' (a menos que você queira atualizá-lo, o que podemos adicionar depois).
          
          # 2. Encontra a Semana
          week = training_block.weeks.find_by(week_number: block_attributes[:week_number])
          unless week
            errors << "Semana #{block_attributes[:week_number]} não encontrada no Bloco '#{training_block.title}'."
            next
          end

          # 3. Cria os Treinos
          treinos_data.each do |treino_data|
            next unless treino_data.is_a?(Hash) 

            exercicios_data = treino_data.delete(:exercicios) || []
            treino_attributes = treino_data.except(:id, :_destroy) 
            
            # Converte 'day' (que vem como string) para Date
            treino_attributes[:day] = Date.parse(treino_attributes[:day]) if treino_attributes[:day].present?

            treino = week.treinos.build(treino_attributes)
            treino.personal_id = @current_user.personal.id
            
            if treino.day.blank?
               errors << "Treino '#{treino.name}': A data do treino é obrigatória."
               next
            end
            if week.start_date.present? && !treino.day.between?(week.start_date, week.end_date)
                errors << "Treino '#{treino.name}': A data #{treino.day.strftime('%d/%m')} está fora do período da semana (#{week.start_date.strftime('%d/%m')} - #{week.end_date.strftime('%d/%m')})."
                next
            end
            unless treino.save
              errors << "Treino '#{treino.name}': #{treino.errors.full_messages.join(', ')}"
              next
            end

            # 4. Cria os Exercícios e Seções
            exercicios_data.each do |ex_data|
              next unless ex_data.is_a?(Hash)
              sections_data = ex_data.delete(:sections) || []
              ex_attributes = ex_data.except(:id, :_destroy)
              exercicio = treino.exercicios.create!(ex_attributes)

              sections_data.each do |sec_data|
                next unless sec_data.is_a?(Hash)
                sec_attributes = sec_data.except(:id, :_destroy)
                exercicio.sections.create!(sec_attributes)
              end
            end
          end
          created_blocks_count += 1
        end 

        raise ActiveRecord::Rollback if errors.present?
      end
    
    rescue ActionController::ParameterMissing => e
      errors << "Formato de dados inválido: #{e.message}"
    rescue ActiveRecord::RecordNotFound
      errors << "Bloco de destino não encontrado."
    rescue ActiveRecord::RecordInvalid => e
      errors << "Falha ao salvar: #{e.message}"
    rescue Date::Error => e
       errors << "Formato de data inválido. Verifique se todas as datas foram preenchidas corretamente."
    end 

    if errors.present?
      render json: { errors: errors.uniq }, status: :unprocessable_entity
    else
      render json: { message: "#{created_blocks_count} planilha(s) importada(s) com sucesso!" }, status: :created
    end
  end


  # --- MÉTODOS PRIVADOS ---
  private

  def set_aluno
    # A rota usa :id para o aluno
    @aluno = @current_user.personal.alunos.find(params[:id]) 
  rescue ActiveRecord::RecordNotFound
     render json: { error: 'Aluno não encontrado.' }, status: :not_found
  end

  def update_weeks_for_block(block)
    block.reload
    current_weeks_count = block.weeks.count
    new_duration = block.weeks_duration.to_i 

    if new_duration > current_weeks_count
      (new_duration - current_weeks_count).times do |i|
        block.weeks.create!(week_number: current_weeks_count + i + 1)
      end
    elsif new_duration < current_weeks_count
      block.weeks.where("week_number > ?", new_duration).destroy_all
    end
  end

  def calculate_and_save_week_dates(block)
    return unless block.start_date.present?
    next_week_start_date = block.start_date
    weeks = block.weeks.order(week_number: :asc)
    weeks.each_with_index do |week, index|
      current_week_start_date = next_week_start_date
      days_until_sunday = (7 - current_week_start_date.wday) % 7
      week_end_date = current_week_start_date + days_until_sunday.days
      is_last_week = (index == weeks.length - 1)
      if is_last_week && block.end_date.present? && block.end_date < week_end_date
          week_end_date = block.end_date
      end
      week.update_columns(start_date: current_week_start_date, end_date: week_end_date)
      next_week_start_date = week_end_date + 1.day
    end
  end

  def parse_spreadsheet(file)
    spreadsheet = Roo::Spreadsheet.open(file.path)
    sheet = spreadsheet.sheet(0)
    block_title = File.basename(file.original_filename, ".*") 
    header_row_index = nil
    week_match = nil
    base_match = nil

    (1..5).each do |i|
      next if sheet.row(i).all?(&:blank?) 
      cell_text = sheet.row(i)[0].to_s.strip
      week_match = cell_text.match(/(?:VARIAÇÃO\s*)?SEMANA (\d+)\s*de\s*(\d+)/i)
      base_match = cell_text.match(/BASE (\d+)/i)
      if week_match || base_match
        header_row_index = i
        break
      end
    end

    unless header_row_index
      raise "Formato de cabeçalho inválido. Não foi possível encontrar 'SEMANA X de Y' ou 'BASE X' nas primeiras 5 linhas."
    end

    week_number = 1
    total_weeks = 4 
    if week_match
      week_number = week_match[1].to_i
      total_weeks = week_match[2].to_i
    elsif base_match
      week_number = base_match[1].to_i
    end

    current_treino_data = nil
    current_exercicio_data = nil
    treinos_data = []

    (header_row_index + 1..sheet.last_row).each do |row_index|
      row = sheet.row(row_index)
      next if row.all?(&:blank?)
      cell_treino_name = row[0].to_s.strip
      cell_carga_raw = row[1].to_s.strip

      if cell_treino_name.match?(/TREINO \d+/i)
        if current_treino_data && current_exercicio_data
           current_treino_data[:exercicios] << current_exercicio_data
        end
        current_treino_data = { name: cell_treino_name, exercicios: [] }
        treinos_data << current_treino_data
        current_exercicio_data = nil
        next 
      end
      
      if cell_treino_name.match?(/CARGA/i) || cell_carga_raw.match?(/CARGA|SÉRIES/i)
        next
      end

      next unless current_treino_data 

      exercicio_name = cell_treino_name
      series = row[2]
      reps = row[3]
      equip = row[4].to_s.strip

      rpe_value_from_carga = nil
      if cell_carga_raw.match?(/RPE/i)
        rpe_match = cell_carga_raw.match(/RPE\s*(\d+(\.\d+)?)/i)
        rpe_value_from_carga = rpe_match[1].to_f if rpe_match
      end

      if exercicio_name.present?
         if current_exercicio_data
            current_treino_data[:exercicios] << current_exercicio_data
         end
         current_exercicio_data = { name: exercicio_name, sections: [] }
      end
      
      next unless current_exercicio_data

      carga_value = nil
      load_unit_value = 'kg' 
      rir_match = cell_carga_raw.match(/RIR\s*(\d+(\.\d+)?)/i)
      
      if rir_match
        carga_value = rir_match[1].to_f
        load_unit_value = 'rir'
      elsif rpe_value_from_carga.present?
        carga_value = nil 
        load_unit_value = nil 
      elsif !cell_carga_raw.blank?
        begin
          carga_value = Float(cell_carga_raw)
          load_unit_value = 'kg'
        rescue ArgumentError
          carga_value = nil
          load_unit_value = nil
        end
      else
         load_unit_value = nil 
      end
      
      if carga_value.present? || series.present? || reps.present? || rpe_value_from_carga.present?
          current_exercicio_data[:sections] << {
            carga: carga_value,
            load_unit: load_unit_value,
            series: series.present? ? series.to_i : nil,
            reps: reps.present? ? reps.to_s.gsub(/S/i, '').to_i : nil,
            equip: equip,
            rpe: rpe_value_from_carga,
            pr: nil,
            feito: false
          }
      end
    end
    
    if current_treino_data && current_exercicio_data
        current_treino_data[:exercicios] << current_exercicio_data
    end

    return {
      block_title: block_title,
      total_weeks: total_weeks,
      week_number: week_number,
      treinos: treinos_data
    }
  end

  def authorize_coach!
    return if @current_user.personal?
    render json: { error: 'Acesso restrito a coaches.' }, status: :forbidden
  end
end