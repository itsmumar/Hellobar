class AddSentAtToEmailCampaigns < ActiveRecord::Migration
  def change
    add_column :email_campaigns, :sent_at, :datetime
  end
end
