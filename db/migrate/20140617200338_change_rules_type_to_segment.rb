class ChangeRulesTypeToSegment < ActiveRecord::Migration
  def change
    rename_column :conditions, :type, :segment
    rename_column :conditions, :operator, :operand
  end
end
