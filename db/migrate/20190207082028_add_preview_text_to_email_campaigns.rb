class AddPreviewTextToEmailCampaigns < ActiveRecord::Migration
  def change
    add_column :emails, :preview_text, :text
  end
end
