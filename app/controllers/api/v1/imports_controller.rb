# app/controllers/api/v1/imports_controller.rb
require 'roo'

class Api::V1::ImportsController < ApplicationController
  before_action :authenticate_request
  before_action :authorize_coach!
  before_action :set_aluno

  # POST /api/v1/alunos/:aluno_id/import_training_block
  def create
    files = params[:files] # Espera um array de arquivos no parâmetro 'files'

    # Validação inicial
    if files.blank? || !files.is_a?(Array)
      return render json: { errors: ["Nenhum arquivo enviado ou formato inválido."] }, status: :unprocessable_entity
    end
    
    # Limita a 5 arquivos por vez (como você sugeriu)
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
      # Retorna os erros encontrados E os dados que foram parseados com sucesso (se houver)
      render json: { errors: errors, parsed_data: parsed_blocks_data }, status: :partial_content # 206 Partial Content
    else
      # Retorna apenas os dados parseados se tudo correu bem
      render json: { parsed_data: parsed_blocks_data }, status: :ok
    end
  end

  private

  def set_aluno
    @aluno = @current_user.personal.alunos.find(params[:aluno_id])
  rescue ActiveRecord::RecordNotFound
     render json: { error: 'Aluno não encontrado.' }, status: :not_found
  end

  # --- Lógica Principal de Parsing ---
  def parse_spreadsheet(file)
    # Roo abre XLSX, XLS, CSV, etc.
    spreadsheet = Roo::Spreadsheet.open(file.path)
    sheet = spreadsheet.sheet(0) # Pega a primeira planilha

    block_title = File.basename(file.original_filename, ".*") # Usa o nome do arquivo como título do bloco
    
    # Extrai dados da primeira linha (Ex: "VARIAÇÃO SEMANA 5 de 8")
    header_row = sheet.row(1) # Primeira linha (índice 1 no Roo)
    week_match = header_row[0]&.match(/SEMANA (\d+)\s*de\s*(\d+)/i)
    unless week_match
        raise "Formato da primeira linha inválido. Esperado 'VARIAÇÃO SEMANA X de Y'."
    end
    week_number = week_match[1].to_i
    total_weeks = week_match[2].to_i

    current_treino_data = nil
    current_exercicio_data = nil
    treinos_data = []

    # Itera pelas linhas da planilha (a partir da linha 4, onde começam os treinos)
    (4..sheet.last_row).each do |row_index|
      row = sheet.row(row_index)
      next if row.all?(&:blank?) # Pula linhas em branco

      # Verifica se é uma linha de início de treino (ex: "TREINO 1")
      if row[0]&.match?(/TREINO \d+/i)
        # Se já estávamos processando um treino, finaliza o último exercício dele
        if current_treino_data && current_exercicio_data
           current_treino_data[:exercicios] << current_exercicio_data
        end
        # Inicia um novo treino
        current_treino_data = { name: row[0].strip, exercicios: [] }
        treinos_data << current_treino_data
        current_exercicio_data = nil # Reseta o exercício atual
        next # Pula para a próxima linha (ignora cabeçalho CARGA, SERIE...)
      end
      
      # Se não começou um treino ainda, pula a linha
      next unless current_treino_data 

      exercicio_name = row[0]&.strip
      carga_raw = row[1].to_s.strip # Coluna B
      series = row[2] # Coluna C
      reps = row[3] # Coluna D
      equip = row[4]&.strip # Coluna E

      # Verifica se é uma nova linha de exercício (nome não está em branco)
      if exercicio_name.present?
         # Se já estávamos processando um exercício, adiciona ele ao treino atual
         if current_exercicio_data
            current_treino_data[:exercicios] << current_exercicio_data
         end
         # Inicia um novo exercício
         current_exercicio_data = { name: exercicio_name, sections: [] }
      end
      
      # Se não temos um exercício atual (ex: linha em branco após nome do treino), pula
      next unless current_exercicio_data

      # Processa os dados da série (mesmo que algumas colunas estejam em branco)
      carga_value = nil
      load_unit_value = 'kg' # Padrão KG
      
      rir_match = carga_raw.match(/RIR\s*(\d+(\.\d+)?)/i)
      if rir_match
        carga_value = rir_match[1].to_f # Pega o número do RIR
        load_unit_value = 'rir'
      elsif !carga_raw.blank?
        begin
          carga_value = Float(carga_raw) # Tenta converter para número
        rescue ArgumentError
          # Se não for número nem RIR, podemos ignorar ou registrar um aviso
          carga_value = nil # Ou talvez manter a string original? Decidiremos depois.
        end
      end
      
      # Adiciona a seção ao exercício atual se houver dados relevantes
      # (Pelo menos carga, series ou reps)
      if carga_value.present? || series.present? || reps.present?
          current_exercicio_data[:sections] << {
            # id: uuid(), # Não precisa gerar ID aqui, o frontend fará isso se necessário
            carga: carga_value,
            load_unit: load_unit_value,
            series: series.present? ? series.to_i : nil,
            reps: reps.present? ? reps.to_s.gsub(/S/i, '').to_i : nil, # Remove 'S' de '20S' se houver
            equip: equip,
            rpe: nil, # A planilha não tem RPE, inicializa como nulo
            pr: nil, # Será calculado no frontend se necessário
            feito: false # Sempre começa como não feito
          }
      end
    end
    
    # Adiciona o último exercício processado ao último treino
    if current_treino_data && current_exercicio_data
        current_treino_data[:exercicios] << current_exercicio_data
    end

    # Estrutura final dos dados parseados para este arquivo
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