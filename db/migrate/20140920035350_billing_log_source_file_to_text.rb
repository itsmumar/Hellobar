class BillingLogSourceFileToText < ActiveRecord::Migration
  def change
    change_column :billing_logs, :source_file, :text
  end
end
