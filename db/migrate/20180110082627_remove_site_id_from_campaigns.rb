class RemoveSiteIdFromCampaigns < ActiveRecord::Migration
  def change
    remove_column :campaigns, :site_id, :integer
  end
end
