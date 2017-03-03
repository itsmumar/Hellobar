class CreateABarCampaign < UserOnboardingCampaign
  def self.final_sequence_index
    0
  end

  def self.users_status_key
    UserOnboardingStatus::STATUSES[:created_site]
  end

  def email_template_name
    "create_a_bar"
  end

  def sequence_index
    0
  end
end
