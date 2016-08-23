class RemoveMobileCodeFromAdmin < ActiveRecord::Migration
  def change
    remove_column :admins, :mobile_code
    remove_column :admins, :mobile_codes_sent
  end
end
