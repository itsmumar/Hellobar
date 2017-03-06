class ConfigureYourBarCampaign < UserOnboardingCampaign
  def self.final_sequence_index
    0
  end

  def self.users_status_key
    UserOnboardingStatus::STATUSES[:selected_goal]
  end

  def email_template_name
    'configure_your_bar'
  end

  def sequence_index
    0
  end
end
