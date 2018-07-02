class RenameSubscriptionScheduleText < ActiveRecord::Migration
  def up
    remove_column :subscriptions, :schedule, :integer
    rename_column :subscriptions, :schedule_text, :schedule
  end

  def down
    rename_column :subscriptions, :schedule, :schedule_text
    add_column :subscriptions, :schedule, :integer
  end
end
