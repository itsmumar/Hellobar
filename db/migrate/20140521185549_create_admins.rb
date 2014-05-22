class CreateAdmins < ActiveRecord::Migration
  def change
    create_table :admins do |t|
      t.string :email, :mobile_phone, :password_hashed, :mobile_code, :session_token, :session_access_token, :permissions_json
      t.datetime :password_last_reset, :session_last_active
      t.integer :mobile_codes_sent, :default => 0
      t.integer :login_attempts, :default => 0
      t.string :valid_access_tokens, :limit => 18000
      t.boolean :locked, :default => false

      t.timestamps
    end

    add_index :admins, :email, :unique => true
    add_index :admins, [:session_token, :session_access_token]
  end
end
