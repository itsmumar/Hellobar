class ChangeAnimatedDefaultValue < ActiveRecord::Migration
  def up
    change_column :site_elements, :animated, :boolean, :default => true
  end

  def down
    change_column :site_elements, :animated, :boolean, :default => false
  end
end
