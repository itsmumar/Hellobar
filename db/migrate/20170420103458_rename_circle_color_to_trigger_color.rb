class RenameCircleColorToTriggerColor < ActiveRecord::Migration
  def change
    rename_column :site_elements, :circle_color, :trigger_color
  end
end
