class CreateContactListLogs < ActiveRecord::Migration
  def change
    create_table :contact_list_logs do |t|
      t.references :contact_list, index: true
      t.string :email
      t.string :name
      t.text :error
      t.boolean :completed, default: false

      t.timestamps
    end
  end
end
