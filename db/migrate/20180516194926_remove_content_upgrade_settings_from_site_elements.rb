class RemoveContentUpgradeSettingsFromSiteElements < ActiveRecord::Migration
  def up
    change_table :site_elements, bulk: true do |t|
      t.remove :offer_headline
      t.remove :disclaimer
      t.remove :content_upgrade_pdf_file_name
      t.remove :content_upgrade_pdf_content_type
      t.remove :content_upgrade_pdf_file_size
      t.remove :content_upgrade_pdf_updated_at
      t.remove :content_upgrade_title
      t.remove :content_upgrade_url
      t.remove :thank_you_enabled
      t.remove :thank_you_headline
      t.remove :thank_you_subheading
      t.remove :thank_you_cta
      t.remove :thank_you_url
    end
  end

  def down
    change_table :site_elements, bulk: true do |t|
      t.string :offer_headline
      t.string :disclaimer
      t.string :content_upgrade_pdf_file_name
      t.string :content_upgrade_pdf_content_type
      t.integer :content_upgrade_pdf_file_size
      t.datetime :content_upgrade_pdf_updated_at
      t.string :content_upgrade_title
      t.text :content_upgrade_url
      t.boolean :thank_you_enabled
      t.string :thank_you_headline
      t.string :thank_you_subheading
      t.string :thank_you_cta
      t.text :thank_you_url
    end
  end
end
