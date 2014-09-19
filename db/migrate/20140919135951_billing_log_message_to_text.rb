class BillingLogMessageToText < ActiveRecord::Migration
  def change
    change_column :billing_logs, :message, :text
  end
end
