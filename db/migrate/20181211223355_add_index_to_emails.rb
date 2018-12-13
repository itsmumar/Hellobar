class AddIndexToEmails < ActiveRecord::Migration
  def change
    add_index :emails, :site_id
    add_index :emails, :subject
  end
end
