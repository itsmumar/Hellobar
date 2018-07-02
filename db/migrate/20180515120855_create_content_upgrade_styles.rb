class CreateContentUpgradeStyles < ActiveRecord::Migration
  def change
    create_table :content_upgrade_styles do |t|
      t.references :site, index: true

      t.string :offer_bg_color
      t.string :offer_text_color
      t.string :offer_link_color
      t.string :offer_border_color
      t.string :offer_border_width
      t.string :offer_border_style
      t.string :offer_border_radius
      t.string :modal_button_color
      t.string :offer_font_size
      t.string :offer_font_weight
      t.string :offer_font_family_name

      t.timestamps null: false
    end
  end
end
