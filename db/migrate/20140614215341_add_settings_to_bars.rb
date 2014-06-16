class AddSettingsToBars < ActiveRecord::Migration
  def change
    add_column :bars, :settings, :text
    add_column :bars, :url, :string
  end
end
