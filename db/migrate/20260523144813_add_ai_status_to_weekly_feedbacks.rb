class AddAiStatusToWeeklyFeedbacks < ActiveRecord::Migration[8.0]
  def up
    add_column :weekly_feedbacks, :ai_status, :integer, default: 0, null: false
    add_column :weekly_feedbacks, :ai_error_message, :text
    add_index  :weekly_feedbacks, :ai_status

    # Backfill heurístico: feedbacks cuja new_week tem treinos IA com sugestões → :completed.
    # Default cobre o resto (:pending). Não tentamos inferir :failed retroativamente.
    say_with_time "Backfilling ai_status for existing weekly_feedbacks" do
      count = 0
      WeeklyFeedback.find_each do |fb|
        source_week = fb.week
        next unless source_week
        block = source_week.training_block
        next_week = block.weeks.find_by(week_number: source_week.week_number + 1)
        next unless next_week

        ai_treinos = next_week.treinos.where(created_by_ai: true)
        next if ai_treinos.empty?

        has_suggestions = AiLoadSuggestion
          .joins(section: { exercicio: :treino })
          .where(treinos: { id: ai_treinos.select(:id) })
          .exists?

        if has_suggestions
          fb.update_column(:ai_status, 2) # 2 = completed
          count += 1
        end
      end
      count
    end
  end

  def down
    remove_index  :weekly_feedbacks, :ai_status
    remove_column :weekly_feedbacks, :ai_error_message
    remove_column :weekly_feedbacks, :ai_status
  end
end
