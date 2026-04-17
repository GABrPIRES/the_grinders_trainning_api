# db/migrate/20260411000006_create_ai_load_suggestions.rb
class CreateAiLoadSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_load_suggestions, id: :uuid do |t|
      t.references :section, type: :uuid, null: false, foreign_key: true

      t.float :suggested_load, null: false
      t.integer :status, default: 0, null: false
      t.boolean :critical, default: false, null: false

      t.timestamps
    end

    add_index :ai_load_suggestions, :status
  end
end
