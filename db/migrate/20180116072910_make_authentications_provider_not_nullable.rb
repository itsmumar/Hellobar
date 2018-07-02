class MakeAuthenticationsProviderNotNullable < ActiveRecord::Migration
  def up
    change_column_null :authentications, :provider, false, 'google_oauth2'
  end

  def down
    change_column_null :authentications, :provider, true
  end
end
