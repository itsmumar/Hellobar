class AddSpamToCampaigns < ActiveRecord::Migration
  def change
    add_column :campaigns, :spam, :boolean, default: false
    add_column :campaigns, :processed, :boolean, default: false
  end
end
