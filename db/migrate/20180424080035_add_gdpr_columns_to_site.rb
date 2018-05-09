class AddGdprColumnsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :privacy_policy_url, :string
    add_column :sites, :terms_and_conditions_url, :string
    add_column :sites, :communication_types, :string, default: Site::COMMUNICATION_TYPES.join(',')
  end
end
