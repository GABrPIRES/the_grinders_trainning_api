class AddPositionToExercicios < ActiveRecord::Migration[8.0]
  def up
    add_column :exercicios, :position, :integer
    add_index  :exercicios, [:treino_id, :position]

    say_with_time "Backfilling position for existing exercicios" do
      count = 0
      Treino.find_each(batch_size: 200) do |treino|
        treino.exercicios.order(:created_at).each_with_index do |ex, idx|
          ex.update_column(:position, idx)
          count += 1
        end
      end
      count
    end

    change_column_null    :exercicios, :position, false
    change_column_default :exercicios, :position, 0
  end

  def down
    remove_index  :exercicios, [:treino_id, :position]
    remove_column :exercicios, :position
  end
end
