class RenameMobilePhoneInAdmin < ActiveRecord::Migration
  def change
    rename_column :admins, :mobile_phone, :initial_password
  end
end
