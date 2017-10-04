class DropContactListLogs < ActiveRecord::Migration
  def up
    drop_table :contact_list_logs
  end
end
