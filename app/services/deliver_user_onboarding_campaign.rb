class DeliverUserOnboardingCampaign
  def initialize(campaign)
    @campaign = campaign
    @onboarding_status = campaign.user.current_onboarding_status
  end

  def call
    return unless current_campaign_sequence

    campaign.deliver_campaign_email!
    mark_sequence_delivered!
  end

  private

  attr_reader :campaign, :onboarding_status

  def current_campaign_sequence
    campaign.sequence_index if campaign.sequence_index && sequence_is_progressing
  end

  def sequence_is_progressing
    return true if onboarding_status.sequence_delivered_last.nil?
    campaign.sequence_index > onboarding_status.sequence_delivered_last
  end

  def mark_sequence_delivered!
    onboarding_status.update_attribute(:sequence_delivered_last, current_campaign_sequence)
  end
end
