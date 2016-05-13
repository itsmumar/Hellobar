class AddApiTokenToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :api_token, :string
    add_index :admins, :api_token
  end
end
