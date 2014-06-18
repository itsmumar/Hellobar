class AddMatchToRules < ActiveRecord::Migration
  def change
    add_column :rules, :match, :string
  end
end
