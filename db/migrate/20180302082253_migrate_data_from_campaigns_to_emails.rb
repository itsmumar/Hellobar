# Models defined inside migration allows to run this migration whenever original models would be removed or modified.
class MigrateDataFromCampaignsToEmails < ActiveRecord::Migration
  CAMPAIGN_TO_EMAILS = %w[from_name from_email subject body created_at updated_at]
  EMAIL_TO_CAMPAIGNS = %w[from_name from_email subject body]

  class CampaignModel < ActiveRecord::Base
    self.table_name = :campaigns
  end

  class EmailModel < ActiveRecord::Base
    self.table_name = :emails

    has_one :campaign, class_name: 'CampaignModel', foreign_key: :email_id
  end

  def up
    CampaignModel.find_each do |campaign|
      email = EmailModel.create!(campaign.attributes.slice(*CAMPAIGN_TO_EMAILS))
      campaign.update!(email_id: email.id)
    end
  end

  def down
    EmailModel.includes(:campaign).find_each do |email|
      if email.campaign
        email.campaign.update!(email.attributes.slice(*EMAIL_TO_CAMPAIGNS))
      else
        puts "Could not find campaign for email (#{email.inspect})"
      end
    end
  end
end
