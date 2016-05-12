class UpgradeHelloBarCampaign < UserOnboardingCampaign
  ORDERED_CAMPAIGN_TEMPLATES = %w(
    upgrade_1
    upgrade_2
    upgrade_3
    upgrade_4
    upgrade_5
    upgrade_6
    upgrade_7
    upgrade_8
    upgrade_9
  )

  def self.final_sequence_index
    ORDERED_CAMPAIGN_TEMPLATES.size - 1
  end

  def self.users_status_key
    UserOnboardingStatus::STATUSES[:installed_script]
  end

  def final_sequence_index
    # don't send the last email to users who only have HB on one site
    sites.count > 1 ? ORDERED_CAMPAIGN_TEMPLATES.size - 1 : ORDERED_CAMPAIGN_TEMPLATES.size - 2
  end

  def sequence_index
    if day_in_campaign <= final_sequence_index
      day_in_campaign
    else
      return nil
    end
  end

  def email_template_name
    return nil unless sequence_index
    ORDERED_CAMPAIGN_TEMPLATES[sequence_index]
  end
end
