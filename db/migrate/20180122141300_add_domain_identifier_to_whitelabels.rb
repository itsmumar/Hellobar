class AddDomainIdentifierToWhitelabels < ActiveRecord::Migration
  def change
    add_column :whitelabels, :domain_identifier, :integer, after: :site_id
  end
end
