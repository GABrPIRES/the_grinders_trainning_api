# app/services/weekly_duplication_service.rb
#
# Clona a semana atual (treinos + exercicios + sections) na próxima semana
# do bloco.
#
# Idempotência (sprint 010): se `new_week` já tem treinos com `created_by_ai: true`
# (1ª execução do job completou a duplicação), reconstrói treino_id_map e
# section_id_map a partir dos treinos existentes em vez de criar novos. Isso
# permite que o retry do WeeklyAiDuplicationJob (após GeminiClient::GeminiError)
# chame Gemini sobre os treinos do 1º run em vez de duplicá-los lado a lado.
#
# Bug de produção corrigido: log 2026-05-22 19:44 mostrou 2 conjuntos de
# TREINO 1/2/3 com mesmo name+day e ~6s de diferença em created_at —
# resultado do retry do ActiveJob criando outra rodada inteira.
#
# Treinos criados aqui ficam marcados com `created_by_ai: true`, permitindo
# que o AiSuggestionPersister sugira cargas apenas neles e que futuras
# rodadas distingam o trabalho da IA do trabalho do coach.
#
# A data (`day`) é ajustada para a janela start_date..end_date da semana
# destino.
class WeeklyDuplicationService
  def initialize(source_week)
    @source_week = source_week
  end

  # Retorna { new_week:, section_id_map: { original_section_id => new_section },
  #            treino_id_map: { original_treino_id => new_treino } }
  def duplicate!
    new_week = nil
    section_id_map = {}
    treino_id_map = {}

    ActiveRecord::Base.transaction do
      new_week = find_or_build_new_week
      new_week.save! if new_week.new_record?

      # Idempotência verdadeira: retry encontra os treinos do 1º run e
      # reusa os IDs sem criar duplicatas.
      if new_week.treinos.where(created_by_ai: true).exists?
        return build_maps_from_existing(new_week)
      end

      @source_week.treinos.includes(exercicios: :sections).each do |treino|
        new_treino = duplicate_treino(treino, new_week)
        treino_id_map[treino.id.to_s] = new_treino

        treino.exercicios.each do |exercicio|
          new_exercicio = duplicate_exercicio(exercicio, new_treino)

          exercicio.sections.each do |section|
            new_section = duplicate_section(section, new_exercicio)
            section_id_map[section.id.to_s] = new_section
          end
        end
      end
    end

    { new_week: new_week, section_id_map: section_id_map, treino_id_map: treino_id_map }
  end

  # Helper estático usado por Coach::WeeklyFeedbacksController#destroy
  # (sprint 010) para localizar a próxima semana sem reexecutar a lógica
  # de criação.
  def self.target_week_of(source_week)
    block = source_week.training_block
    block.weeks.find_by(week_number: source_week.week_number + 1)
  end

  private

  # Reconstrói treino_id_map e section_id_map a partir dos treinos
  # `created_by_ai: true` já presentes na new_week (1º run do job). Pareia
  # source ↔ target por (name, adjusted_day). Para exercícios usa name como
  # match primário e index posicional como fallback. Para sections usa
  # index posicional dentro do exercício casado.
  def build_maps_from_existing(new_week)
    treino_id_map = {}
    section_id_map = {}
    existing = new_week.treinos.where(created_by_ai: true).includes(exercicios: :sections).to_a

    @source_week.treinos.includes(exercicios: :sections).each do |src_treino|
      target_day = adjusted_day(src_treino, new_week)
      matched_treino = existing.find do |t|
        t.name == src_treino.name && t.day&.to_date == target_day&.to_date
      end
      next unless matched_treino
      treino_id_map[src_treino.id.to_s] = matched_treino

      src_exercicios = src_treino.exercicios.to_a
      target_exercicios = matched_treino.exercicios.to_a

      src_exercicios.each_with_index do |src_ex, ex_idx|
        matched_ex = target_exercicios.find { |e| e.name == src_ex.name } ||
                     target_exercicios[ex_idx]
        next unless matched_ex

        target_sections = matched_ex.sections.to_a
        src_ex.sections.each_with_index do |src_sec, sec_idx|
          matched_sec = target_sections[sec_idx]
          section_id_map[src_sec.id.to_s] = matched_sec if matched_sec
        end
      end
    end

    { new_week: new_week, section_id_map: section_id_map, treino_id_map: treino_id_map }
  end

  # Reutiliza a próxima semana se já existe no bloco; caso contrário, cria.
  def find_or_build_new_week
    block = @source_week.training_block
    next_number = @source_week.week_number + 1
    candidate = block.weeks.find_by(week_number: next_number)
    return candidate if candidate

    last_number = block.weeks.maximum(:week_number) || @source_week.week_number
    block.weeks.build(
      week_number: last_number + 1,
      start_date: @source_week.end_date ? @source_week.end_date + 1 : nil,
      end_date: @source_week.end_date ? @source_week.end_date + 7 : nil
    )
  end

  def duplicate_treino(treino, new_week)
    new_week.treinos.create!(
      name: treino.name,
      day: adjusted_day(treino, new_week),
      personal_id: treino.personal_id,
      status: :draft,
      created_by_ai: true
    )
  end

  # Ajusta a data do treino fonte para a janela [start_date, end_date] da
  # semana destino, preservando o weekday original. Se o offset cair fora
  # da janela, força para o weekday correspondente dentro de target_week.
  def adjusted_day(source_treino, target_week)
    return nil unless source_treino.day && target_week.start_date

    source_offset = (source_treino.day.to_date - @source_week.start_date).to_i
    base = target_week.start_date + source_offset.days

    return base if target_week.end_date.nil? || base.between?(target_week.start_date, target_week.end_date)

    # Fallback: encontra dia com o mesmo weekday dentro da janela target.
    weekday = source_treino.day.wday
    (0..6).each do |delta|
      candidate = target_week.start_date + delta.days
      return candidate if candidate.wday == weekday
    end
    base
  end

  def duplicate_exercicio(exercicio, new_treino)
    new_treino.exercicios.create!(
      name: exercicio.name
      # observation starts nil — fresh week, fresh notes
      # position é setado pelo before_validation callback do model (Fase 3)
    )
  end

  def duplicate_section(section, new_exercicio)
    new_exercicio.sections.create!(
      carga: section.carga,
      series: section.series,
      reps: section.reps,
      equip: section.equip,
      rpe: section.rpe,
      load_unit: section.load_unit,
      pr: section.pr,
      feito: false
      # actual_load, actual_rpe start nil — to be filled by the student
    )
  end
end
