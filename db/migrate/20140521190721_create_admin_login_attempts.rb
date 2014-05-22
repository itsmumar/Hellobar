class CreateAdminLoginAttempts < ActiveRecord::Migration
  def change
    create_table :admin_login_attempts do |t|
      t.string :email, :ip_address, :user_agent, :access_cookie
      t.datetime :attempted_at
    end
  end
end
