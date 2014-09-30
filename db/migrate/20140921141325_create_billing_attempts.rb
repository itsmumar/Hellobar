class CreateBillingAttempts < ActiveRecord::Migration
  def change
    create_table :billing_attempts do |t|
      t.belongs_to :bill
      t.belongs_to :payment_method_details
      t.integer :status
      t.string :response

      t.datetime :created_at
    end
  end
end
