class AddMigratedToContactListLogs < ActiveRecord::Migration
  def change
    # updating 10mln records + updating index; what could possibly go wrong?
    add_column :contact_list_logs, :migrated, :boolean, default: false, null: false, index: true
  end
end
