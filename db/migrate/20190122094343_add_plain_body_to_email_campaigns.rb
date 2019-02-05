class AddPlainBodyToEmailCampaigns < ActiveRecord::Migration
  def change
    add_column :emails, :plain_body, :text
  end
end
