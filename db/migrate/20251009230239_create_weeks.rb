# db/migrate/xxxxxxxx_create_weeks.rb
class CreateWeeks < ActiveRecord::Migration[8.0]
  def change
    create_table :weeks, id: :uuid do |t| # <--- AJUSTE 1: id: :uuid
      t.integer :week_number
      t.references :training_block, null: false, foreign_key: true, type: :uuid # <--- AJUSTE 2: type: :uuid
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end