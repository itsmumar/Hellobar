class DeleteValidAccessTokensFromAdmins < ActiveRecord::Migration
  def up
    remove_column :admins, :valid_access_tokens
    remove_column :admins, :session_access_token
    remove_index :admins, [:session_token, :session_access_token]
    add_index :admins, :session_token
  end

  def down
    add_column :admins, :valid_access_tokens, :string, limit: 18000
    add_column :admins, :session_access_token, :string
    remove_index :admins, :session_token
    add_index :admins, [:session_token, :session_access_token]
  end
end
