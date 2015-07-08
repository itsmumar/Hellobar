class AddInstallTypeToSite < ActiveRecord::Migration
  def change
    add_column :sites, :install_type, :string
  end
end
