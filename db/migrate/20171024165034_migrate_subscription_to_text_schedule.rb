class MigrateSubscriptionToTextSchedule < ActiveRecord::Migration
  def up
    add_column :subscriptions, :schedule_text, :string,
      null: false, default: Subscription::MONTHLY, limit: 20
    Subscription.where(schedule: 0).update_all schedule_text: Subscription::MONTHLY
    Subscription.where(schedule: 1).update_all schedule_text: Subscription::YEARLY
  end

  def down
    Subscription.where(schedule_text: Subscription::MONTHLY).update_all schedule: 0
    Subscription.where(schedule_text: Subscription::YEARLY).update_all schedule: 1
    remove_column :subscriptions, :schedule_text
  end
end
