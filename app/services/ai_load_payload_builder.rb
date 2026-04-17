# app/services/ai_load_payload_builder.rb
#
# Constrói o payload otimizado para enviar ao Gemini.
# Agrupa exercícios por treino e inclui o treino_id da nova semana,
# necessário para que o Gemini retorne a observação por treino.
class AiLoadPayloadBuilder
  def initialize(week, weekly_feedback, treino_id_map, target_goal: nil)
    @week = week
    @weekly_feedback = weekly_feedback
    # treino_id_map: { old_treino_id_string => new_treino }
    @treino_id_map = treino_id_map
    # target_goal: periodization_goal da próxima semana (a que será gerada),
    # não da semana concluída. Fallback para a própria semana ou "maintenance".
    @target_goal = target_goal
  end

  def build
    {
      periodization_goal: @target_goal || @week.periodization_goal || "maintenance",
      weekly_feedback: feedback_data,
      treinos: treinos_data
    }.to_json
  end

  private

  def feedback_data
    {
      sleep_level: @weekly_feedback.sleep_level,
      stress_level: @weekly_feedback.stress_level,
      diet_level: @weekly_feedback.diet_level,
      body_weight: @weekly_feedback.body_weight,
      training_desire: @weekly_feedback.training_desire,
      general_evaluation: @weekly_feedback.general_evaluation
    }
  end

  def treinos_data
    @week.treinos.completed.map do |treino|
      new_treino = @treino_id_map[treino.id.to_s]
      {
        treino_id: new_treino&.id,
        treino_name: treino.name,
        exercises: exercises_data(treino)
      }
    end
  end

  def exercises_data(treino)
    treino.exercicios.map do |exercicio|
      {
        exercise_name: exercicio.name,
        observation: exercicio.observation.presence,
        sections: sections_data(exercicio)
      }
    end
  end

  def sections_data(exercicio)
    exercicio.sections.map do |section|
      {
        section_id: section.id,
        prescribed_load: section.carga,
        actual_load: section.actual_load,
        expected_rpe: section.rpe,
        actual_rpe: section.actual_rpe,
        reps: section.reps,
        completed: section.feito
      }
    end
  end
end
