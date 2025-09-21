# db/migrate/xxxxxxxx_create_alunos.rb
class CreateAlunos < ActiveRecord::Migration[8.0]
  def change
    create_table :alunos, id: :uuid do |t|
      # Adicionamos a referência explícita ao User
      t.references :user, type: :uuid, null: false, foreign_key: true

      # A referência a 'personal' já foi criada pelo gerador, o que é ótimo.

      t.date :birth_date
      t.float :weight
      t.float :height
      t.text :lesao
      t.string :phone_number, null: false
      t.text :restricao_medica
      t.text :objetivo
      t.integer :treinos_semana
      t.integer :tempo_treino
      t.integer :horario_treino
      t.integer :pr_supino
      t.integer :pr_terra
      t.integer :pr_agachamento
      t.integer :new_pr_supino
      t.integer :new_pr_terra
      t.integer :new_pr_agachamento

      t.timestamps
    end
  end
end