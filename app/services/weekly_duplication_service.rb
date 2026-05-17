# app/services/weekly_duplication_service.rb
#
# Clona a semana atual (treinos + exercicios + sections) na próxima semana
# do bloco, **preservando** qualquer treino que o coach já tenha criado
# manualmente no destino. A dedup acontece por (weekday, name) — se o destino
# já tem um treino com o mesmo nome no mesmo dia da semana, o do destino é
# preservado (não duplicamos nem destruímos).
#
# Treinos criados aqui são marcados com `created_by_ai: true`, permitindo
# que o AiSuggestionPersister sugira cargas apenas neles e que futuras
# rodadas de duplicação distingam o trabalho da IA do trabalho do coach.
#
# A data (`day`) é ajustada para a janela start_date..end_date da semana
# destino — corrige bug observado em sprint 004 onde a IA copiava o day
# literal da semana fonte.
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

      @source_week.treinos.includes(exercicios: :sections).each do |treino|
        # Dedup: se destino já tem um treino mesmo nome+weekday, preserva o destino
        # e não duplica este da origem.
        next if existing_treino_in_target?(treino, new_week)

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

  private

  # Reutiliza a próxima semana se já existe no bloco; caso contrário, cria.
  # IMPORTANTE: não destrói mais drafts do destino — agora dedupamos por
  # (weekday, name) durante a iteração de treinos, preservando trabalho do coach.
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

  # Dedup: já existe um treino no destino com mesmo nome + mesmo weekday?
  # Considera o weekday calculado pela `adjusted_day` (não pelo `day` original
  # da fonte) para que datas pré-ajustadas não confundam a checagem.
  def existing_treino_in_target?(source_treino, target_week)
    target_day = adjusted_day(source_treino, target_week)
    return false if target_day.nil?

    target_week.treinos.where(name: source_treino.name).any? do |t|
      t.day&.wday == target_day.wday
    end
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
