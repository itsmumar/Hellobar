class AddThankYouFieldsToSiteElements < ActiveRecord::Migration
  def change
    add_column :site_elements, :thank_you_enabled, :boolean, default: false
    add_column :site_elements, :thank_you_headline, :string
    add_column :site_elements, :thank_you_subheading, :string
    add_column :site_elements, :thank_you_cta, :string
    add_column :site_elements, :thank_you_url, :text, limit: 500
  end
end
