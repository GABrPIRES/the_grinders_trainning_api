# db/migrate/xxxxxxxx_enable_pgcrypto_extension.rb
class EnablePgcryptoExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto'
  end
end