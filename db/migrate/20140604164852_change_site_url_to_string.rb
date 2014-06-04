class ChangeSiteURLToString < ActiveRecord::Migration
  def change
    change_column :sites, :url, :string
  end
end
