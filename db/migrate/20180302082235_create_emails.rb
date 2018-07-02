class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.string :from_name, null: false
      t.string :from_email, null: false
      t.string :subject, null: false
      t.text :body, null: false

      t.timestamps
      t.datetime :deleted_at
    end

    add_column :campaigns, :email_id, :integer
  end
end
