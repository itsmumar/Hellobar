class AddEditableToRules < ActiveRecord::Migration
  def change
    add_column :rules, :editable, :boolean, default: true
  end
end
