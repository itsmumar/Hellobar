class MigrateDataFromCampaignsToEmails < ActiveRecord::Migration
  CAMPAIGN_TO_EMAILS = %w[from_name from_email subject body created_at updated_at]
  EMAIL_TO_CAMPAIGNS = %w[from_name from_email subject body]

  def up
    Campaign.unscoped.find_each do |campaign|
      campaign.create_email!(campaign.attributes.slice(*CAMPAIGN_TO_EMAILS))
    end
  end

  def down
    Campaign.unscoped.find_each do |campaign|
      if campaign.email
        campaign.update!(campaign.email.attributes.slice(*EMAIL_TO_CAMPAIGNS))
      else
        puts "Could not find campaign for email (#{ campaign.email.inspect })"
      end
    end
  end
end
