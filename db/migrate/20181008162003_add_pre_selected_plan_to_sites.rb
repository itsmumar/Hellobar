class AddPreSelectedPlanToSites < ActiveRecord::Migration
  def change
    add_column :sites, :pre_selected_plan, :string
  end
end
