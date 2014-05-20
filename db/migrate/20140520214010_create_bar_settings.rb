class CreateBarSettings < ActiveRecord::Migration
  def change
    # TODO: go through comps to verify all of these are
    #       still being used / need to be migrated.
    create_table :bar_settings do |t|
      t.with_options :default => false do |default_false|
        default_false.boolean :closable
        default_false.boolean :hide_destination
        default_false.boolean :open_in_new_window
        default_false.boolean :pushes_page_down
        default_false.boolean :remains_at_top
        default_false.boolean :show_border
      end

      t.integer :hide_after
      t.integer :show_wait
      t.integer :wiggle_wait

      t.string :bar_color, :border_color, :button_color,
        :font, :link_color, :link_style, :link_text,
        :message, :size, :tab_side, :target, :text_color,
        :texture, :thank_you_text

      t.belongs_to :bar

      t.timestamps
    end

    add_index :bar_settings, :bar_id, :unique => true
  end
end
