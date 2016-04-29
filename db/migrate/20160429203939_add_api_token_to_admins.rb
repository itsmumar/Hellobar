class AddApiTokenToAdmins < ActiveRecord::Migration
  def change
    add_column :admins, :api_token, :string
    add_index :admins, :api_token

    Admin.reset_column_information

    Admin.all.each do |admin|
      admin.update(api_token: SecureRandom.base64)
    end
  end
end
