class SetNullsAndDefaultValuesForAlertsInSiteElements < ActiveRecord::Migration
  def up
    change_column_default :site_elements, :sound, 'none'
    change_column_default :site_elements, :trigger_color, '31b5ff'

    change_column_null :site_elements, :notification_delay, false, 10
    change_column_null :site_elements, :sound, false, 'none'
    change_column_null :site_elements, :trigger_color, false, '31b5ff'
  end

  def down
    change_column_default :site_elements, :sound, nil
    change_column_default :site_elements, :trigger_color, nil

    change_column_null :site_elements, :notification_delay, true
    change_column_null :site_elements, :sound, true
    change_column_null :site_elements, :trigger_color, true
  end
end
