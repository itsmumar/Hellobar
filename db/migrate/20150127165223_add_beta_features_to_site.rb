class AddBetaFeaturesToSite < ActiveRecord::Migration
  def change
    add_column :sites, :beta_features, :boolean, default: false
  end
end
