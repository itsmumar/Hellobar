class UpdateCampaignDefaultStatus < ActiveRecord::Migration
  def up
    change_column_default :campaigns, :status, Campaign::DRAFT
  end

  def down
    change_column_default :campaigns, :status, 'new'
  end
end
