class AddStripeInvoiceIdToBills < ActiveRecord::Migration
  def change
    add_column :bills, :stripe_invoice_id, :string
  end
end
