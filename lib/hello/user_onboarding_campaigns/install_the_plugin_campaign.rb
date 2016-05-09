class InstallThePluginCampaign < UserOnboardingCampaign
  ORDERED_CAMPAIGN_TEMPLATES = %w(
    install_1
    install_2
    install_3
    install_4
    install_5
    install_6
    install_7
  )

  def self.final_sequence_index
    ORDERED_CAMPAIGN_TEMPLATES.size - 1
  end

  def self.users_status_key
    UserOnboardingStatus::STATUSES[:created_element]
  end

  def sequence_index
    # sequence is everyday for 4 days, then start skipping days.
    # return nil if they have finished the campaign.
    {
      0  => 0,
      1  => 1,
      2  => 2,
      3  => 3,
      5  => 4,
      8  => 5,
      10 => 6
    }[day_in_campaign]
  end

  def email_template_name
    return nil unless sequence_index
    ORDERED_CAMPAIGN_TEMPLATES[sequence_index]
  end
end