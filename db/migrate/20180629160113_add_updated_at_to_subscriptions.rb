class AddUpdatedAtToSubscriptions < ActiveRecord::Migration
  def self.up
    add_column :subscriptions, :updated_at, :datetime
    Subscription.update_all("updated_at=created_at")
  end

  def self.down
    remove_column :subscriptions, :updated_at
  end
end
