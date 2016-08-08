class AddAuthenticationCodeToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :authentication_code, :string
  end
end
