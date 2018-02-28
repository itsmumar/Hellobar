class UpdateCampaign
  def initialize(campaign, attributes)
    @campaign = campaign
    @attributes = attributes
  end

  def call
    ensure_campaign_is_editable!
    update_campaign
  end

  private

  attr_reader :campaign, :attributes

  def ensure_campaign_is_editable!
    return if campaign.draft?
    campaign.errors.add :base, 'is not editable'
    raise(ActiveRecord::RecordInvalid, campaign)
  end

  def update_campaign
    campaign.update!(attributes)
  end
end
