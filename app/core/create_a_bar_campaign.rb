class CreateABarCampaign
  FINAL_SEQUENCE_INDEX = 0

  def self.users
    User
      .join_current_onboarding_status
      .onboarding_sequence_before(FINAL_SEQUENCE_INDEX)
      .merge(UserOnboardingStatus.with_status(:created_site))
  end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def sequence_index
    0
  end

  def deliver_campaign_email!
    DripCampaignMailer.create_a_bar(user).deliver_later
  end
end
