class RenameRulesToConditions < ActiveRecord::Migration
  def change
    rename_table :rules, :conditions
  end
end
