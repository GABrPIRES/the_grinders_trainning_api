class AddSignupFieldsToUsersAndPersonals < ActiveRecord::Migration[8.0]
  def change
    # Alterações na tabela Users
    add_column :users, :verification_token, :string
    add_column :users, :email_verified_at, :datetime
    add_index :users, :verification_token, unique: true
    
    # Alterações na tabela Personals
    add_column :personals, :signup_code, :string
    add_column :personals, :signup_code_expires_at, :datetime
    add_column :personals, :auto_approve_students, :boolean, default: false
    add_index :personals, :signup_code, unique: true
  end
end