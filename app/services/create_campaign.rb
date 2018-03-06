class CreateCampaign
  def initialize(site, attributes)
    @site = site
    @attributes = attributes
  end

  def call
    campaign = site.campaigns.build(attributes)
    campaign.save!
  end

  private

  attr_reader :site, :attributes
end
