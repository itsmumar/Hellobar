class ConsolidateBarAndBarSettings < ActiveRecord::Migration
  def change
    drop_table :bar_settings

    add_column :bars, :closable, :boolean, default: false
    add_column :bars, :hide_destination, :boolean, default: false
    add_column :bars, :open_in_new_window, :boolean, default: false
    add_column :bars, :pushes_page_down, :boolean, default: false
    add_column :bars, :remains_at_top, :boolean, default: false
    add_column :bars, :show_border, :boolean, default: false

    add_column :bars, :hide_after, :integer, default: 0
    add_column :bars, :show_wait, :integer
    add_column :bars, :wiggle_wait, :integer, default: 0

    add_column :bars, :bar_color, :string, default: 'eb593c'
    add_column :bars, :border_color, :string, default: 'ffffff'
    add_column :bars, :button_color, :string, default: '000000'
    add_column :bars, :font, :string, default: 'Helvetica,Arial,sans-serif'
    add_column :bars, :link_color, :string, default: 'ffffff'
    add_column :bars, :link_style, :string, default: 'button'
    add_column :bars, :link_text, :string, default: 'Click Here'
    add_column :bars, :message, :string, default: 'Hello. Add your message here.'
    add_column :bars, :size, :string, default: 'large'
    add_column :bars, :tab_side, :string, default: 'right'
    add_column :bars, :target, :string
    add_column :bars, :text_color, :string, default: 'ffffff'
    add_column :bars, :texture, :string, default: 'none'
    add_column :bars, :thank_you_text, :string, default: 'Thank you for signing up!'
  end
end
