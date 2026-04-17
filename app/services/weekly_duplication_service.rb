# app/services/weekly_duplication_service.rb
#
# Clona a semana atual (treinos + exercicios + sections), cria os novos
# treinos como draft e retorna o mapeamento de IDs originais → novas sections,
# necessário para o AiSuggestionPersister.
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

  # Usa a semana seguinte já existente se estiver vazia ou tiver apenas drafts
  # (drafts = gerados por rodada anterior do AI, ainda não publicados pelo coach).
  # Nesse caso, limpa os drafts antigos e reutiliza a semana, preservando
  # periodization_goal e datas definidas pelo coach.
  # Caso a semana seguinte já tenha treinos não-draft (publicados/em andamento),
  # cria uma nova semana após a última existente.
  def find_or_build_new_week
    block = @source_week.training_block
    next_number = @source_week.week_number + 1
    candidate = block.weeks.find_by(week_number: next_number)

    if candidate
      has_active_treinos = candidate.treinos.where.not(status: :draft).exists?
      unless has_active_treinos
        # Limpa drafts antigos de rodadas anteriores antes de re-duplicar
        candidate.treinos.where(status: :draft).destroy_all
        return candidate
      end
    end

    # Cria nova semana após a última existente
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
      day: treino.day,
      personal_id: treino.personal_id,
      status: :draft
    )
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
