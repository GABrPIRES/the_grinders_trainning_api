# db/migrate/xxxxxxxx_create_payment_methods.rb
class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_methods, id: :uuid do |t|
      t.integer :method_type, null: false
      t.jsonb :details, null: false, default: {}
      t.references :personal, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end