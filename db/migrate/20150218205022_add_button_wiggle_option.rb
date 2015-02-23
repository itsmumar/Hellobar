class AddButtonWiggleOption < ActiveRecord::Migration
  def change
    add_column :site_elements, :wiggle_button, :boolean, default: false
  end
end
