class AddStacktraceToContactListLogs < ActiveRecord::Migration
  def change
    add_column :contact_list_logs, :stacktrace, :text
  end
end
