class AddEmailDigestOptInToSites < ActiveRecord::Migration
  def change
    add_column :sites, :opted_in_to_email_digest, :boolean, :default => true
  end
end
