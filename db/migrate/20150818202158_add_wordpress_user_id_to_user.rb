class AddWordpressUserIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :wordpress_user_id, :integer
  end
end
