class AddContentUpgradeFields < ActiveRecord::Migration
  def change
    add_column :site_elements, :offer_headline, :string
    add_column :site_elements, :offer_text, :string
    add_column :site_elements, :disclaimer, :string
    add_column :site_elements, :content, :text
  end
end
