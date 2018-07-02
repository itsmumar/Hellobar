class AddUpdatedAtToSubscriptions < ActiveRecord::Migration
  def up
    add_column :subscriptions, :updated_at, :datetime
    Subscription.update_all("updated_at=created_at")
  end

  def down
    remove_column :subscriptions, :updated_at
  end
end
