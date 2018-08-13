class ChangeDefaultViewCondition < ActiveRecord::Migration
  def change
    change_column_default(:site_elements, :view_condition, 'wait-5')
  end
end
