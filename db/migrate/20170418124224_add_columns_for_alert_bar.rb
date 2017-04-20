class AddColumnsForAlertBar < ActiveRecord::Migration
  def change
    add_column :site_elements, :sound, :string
    add_column :site_elements, :notification_delay, :integer, default: 10
    add_column :site_elements, :circle_color, :string
  end
end
