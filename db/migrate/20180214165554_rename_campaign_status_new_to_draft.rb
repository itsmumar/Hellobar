class RenameCampaignStatusNewToDraft < ActiveRecord::Migration
  def up
    Campaign.where(status: 'new').update_all(status: Campaign::DRAFT)
  end

  def down
    Campaign.where(status: Campaign::DRAFT).update_all(status: 'new')
  end
end
