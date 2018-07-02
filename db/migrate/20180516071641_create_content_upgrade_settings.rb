class CreateContentUpgradeSettings < ActiveRecord::Migration
  def change
    create_table :content_upgrade_settings do |t|
      t.references :content_upgrade, index: true

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

      t.timestamps null: false
    end
  end
end
