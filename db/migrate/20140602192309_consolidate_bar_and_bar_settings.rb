class ConsolidateBarAndBarSettings < ActiveRecord::Migration
  def change
    drop_table :bar_settings

    add_column :bars, :closable, :boolean, default: false
    add_column :bars, :hide_destination, :boolean, default: false
    add_column :bars, :open_in_new_window, :boolean, default: false
    add_column :bars, :pushes_page_down, :boolean, default: false
    add_column :bars, :remains_at_top, :boolean, default: false
    add_column :bars, :show_border, :boolean, default: false

    add_column :bars, :hide_after, :integer
    add_column :bars, :show_wait, :integer
    add_column :bars, :wiggle_wait, :integer

    add_column :bars, :bar_color, :string
    add_column :bars, :border_color, :string
    add_column :bars, :button_color, :string
    add_column :bars, :font, :string
    add_column :bars, :link_color, :string
    add_column :bars, :link_style, :string
    add_column :bars, :link_text, :string
    add_column :bars, :message, :string
    add_column :bars, :size, :string
    add_column :bars, :tab_side, :string
    add_column :bars, :target, :string
    add_column :bars, :text_color, :string
    add_column :bars, :texture, :string
    add_column :bars, :thank_you_text, :string
  end
end
