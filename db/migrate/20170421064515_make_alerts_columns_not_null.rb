class MakeAlertsColumnsNotNull < ActiveRecord::Migration
  def change
    change_column_null :site_elements, :trigger_color, false, '31b5ff'
    change_column_null :site_elements, :sound, false, 'none'
    change_column_null :site_elements, :notification_delay, false
  end
end
