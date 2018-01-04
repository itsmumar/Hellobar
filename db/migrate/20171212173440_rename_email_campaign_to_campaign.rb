class RenameEmailCampaignToCampaign < ActiveRecord::Migration
  def change
    rename_table :email_campaigns, :campaigns
  end
end
