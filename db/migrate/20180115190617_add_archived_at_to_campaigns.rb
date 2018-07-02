class AddArchivedAtToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :archived_at, :datetime
  end
end
