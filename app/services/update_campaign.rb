class UpdateCampaign
  EMAIL_ATTRIBUTES = %i[from_name from_email subject body].freeze

  def initialize(campaign, attributes)
    @campaign = campaign
    @attributes = attributes
  end

  def call
    ensure_campaign_is_editable!
    ensure_campaign_email!
    split_attributes!

    Campaign.transaction do
      update_email!
      update_campaign!
    end
  end

  private

  attr_reader :campaign, :attributes, :email_attributes

  def ensure_campaign_is_editable!
    return if campaign.draft?
    campaign.errors.add :base, 'is not editable'
    raise(ActiveRecord::RecordInvalid, campaign)
  end

  def ensure_campaign_email!
    campaign.build_email unless campaign.email
  end

  def split_attributes!
    @email_attributes = attributes.extract!(*EMAIL_ATTRIBUTES)
  end

  def update_email!
    campaign.email.update!(email_attributes)
  end

  def update_campaign!
    campaign.update!(attributes)
  end
end
