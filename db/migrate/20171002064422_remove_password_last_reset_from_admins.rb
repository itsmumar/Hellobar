class RemovePasswordLastResetFromAdmins < ActiveRecord::Migration
  def change
    remove_column :admins, :password_last_reset, :datetime
  end
end
