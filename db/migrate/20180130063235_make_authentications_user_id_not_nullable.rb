class MakeAuthenticationsUserIdNotNullable < ActiveRecord::Migration
  def up
    Authentication.where(user_id: nil).delete_all
    change_column_null :authentications, :user_id, false
  end

  def down
    change_column_null :authentications, :user_id, true
  end
end
