class BringBackDefaultValuesForAlertColumns < ActiveRecord::Migration
  def up
    change_column_default :site_elements, :sound, 'none'
    change_column_default :site_elements, :trigger_color, '31b5ff'
  end

  def down
    change_column_default :site_elements, :sound, nil
    change_column_default :site_elements, :trigger_color, nil
  end
end
