# db/migrate/xxxxxxxx_add_load_unit_to_sections.rb
class AddLoadUnitToSections < ActiveRecord::Migration[8.0]
  def change
    add_column :sections, :load_unit, :string, default: 'kg', null: true
  end
end