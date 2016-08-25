class AddRotpSecretBaseToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :rotp_secret_base, :string
  end
end
