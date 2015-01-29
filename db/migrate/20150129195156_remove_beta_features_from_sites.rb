class RemoveBetaFeaturesFromSites < ActiveRecord::Migration
  def change
    remove_column :sites, :beta_features
  end
end
