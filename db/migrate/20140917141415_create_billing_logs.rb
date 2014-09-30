class CreateBillingLogs < ActiveRecord::Migration
  def change
    create_table :billing_logs do |t|
      t.string :message, :index=>true
      t.string :source_file
      t.datetime :created_at
      t.integer :user_id, :index=>true
      t.integer :site_id, :index=>true
      t.integer :subscription_id, :index=>true
      t.integer :payment_method_id, :index=>true
      t.integer :payment_method_details_id, :index=>true
      t.integer :bill_id, :index=>true
      t.integer :billing_attempt_id, :index=>true
    end
  end
end
