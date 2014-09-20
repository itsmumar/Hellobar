class CreateBills < ActiveRecord::Migration
  def change
    create_table :bills do |t|
      t.belongs_to :subscription
      t.integer :status, :default=>0
      t.string :type
      t.decimal :amount, :precision=>7, :scale=>2
      t.string :description
      t.string :metadata
      t.boolean :grace_period_allowed
      t.datetime :bill_at
      t.datetime :start_date
      t.datetime :ends_date
      t.datetime :changed_status_at
      t.datetime :created_at
    end
  end
end
