class DeliverOnboardingCampaigns
  def initialize(campaign_classes = [ConfigureYourBarCampaign, CreateABarCampaign])
    @campaign_classes = campaign_classes
  end

  def call
    campaign_classes.each do |campaign_class|
      deliver_campaing(campaign_class)
    end
  end

  private

  attr_reader :campaign_classes

  def deliver_campaing(campaign_class)
    campaign_class.users.each do |user|
      deliver_to_user campaign_class, user
    end
  end

  def deliver_to_user(campaign_class, user)
    campaign = campaign_class.new(user)
    DeliverUserOnboardingCampaign.new(campaign).call
  end
end
