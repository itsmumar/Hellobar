class AddUpsellEmailSentToSites < ActiveRecord::Migration
  def change
    add_column :sites, :upsell_email_sent, :boolean, default: false
  end
end
