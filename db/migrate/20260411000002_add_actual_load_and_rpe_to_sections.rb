# db/migrate/20260411000002_add_actual_load_and_rpe_to_sections.rb
class AddActualLoadAndRpeToSections < ActiveRecord::Migration[8.0]
  def change
    # `carga` (float) continua sendo a carga prescrita pelo coach.
    # `rpe` (float) continua sendo o RPE esperado pelo coach.
    # As colunas abaixo representam o que o aluno efetivamente realizou.
    add_column :sections, :actual_load, :float
    add_column :sections, :actual_rpe, :float
  end
end
