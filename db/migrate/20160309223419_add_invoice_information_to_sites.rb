class AddInvoiceInformationToSites < ActiveRecord::Migration
  def change
    add_column :sites, :invoice_information, :text
  end
end
