class CreateEmailCampaigns < ActiveRecord::Migration
  def change
    create_table :email_campaigns do |t|
      t.integer :site_id, null: false
      t.integer :contact_list_id, null: false
      t.string :name, null: false
      t.string :from_name, null: false
      t.string :from_email, null: false
      t.string :subject, null: false
      t.string :body, null: false
      t.string :status, null: false, limit: 20, default: 'new'
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :email_campaigns, :site_id
    add_index :email_campaigns, :deleted_at
  end
end
