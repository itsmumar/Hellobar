class UserOnboardingCampaign
  attr_reader :user, :onboarding_status, :sites, :onboarding_status_name

  def self.onboarding_campaign_classes
    [ConfigureYourBarCampaign, CreateABarCampaign]
  end

  def self.deliver_all_onboarding_campaign_email!
    onboarding_campaign_classes.each do |campaign_class|
      campaign_class.users.each do |user|
        campaign = campaign_class.new(user, user.current_onboarding_status)

        campaign.current_campaign_sequence &&
        campaign.deliver_campaign_email! &&
        campaign.mark_sequence_delivered!
      end
    end
  end

  def self.users
    User.join_current_onboarding_status.
         onboarding_sequence_before(final_sequence_index).
         where('user_onboarding_statuses.status_id = ?', users_status_key)
  end

  def initialize(user, onboarding_status)
    raise 'onboarding status required' unless onboarding_status.is_a?(UserOnboardingStatus)

    @user = user
    @sites = user.sites
    @onboarding_status = onboarding_status
    @onboarding_status_name = onboarding_status.status_name
  end

  def campaign_entered_at
    onboarding_status.created_at.utc
  end

  def day_in_campaign
    (Time.current.utc - campaign_entered_at).to_i / 1.day
  end

  def current_campaign_sequence
    return nil unless sequence_index
    return nil unless sequence_is_progressing

    sequence_index
  end

  def sequence_is_progressing
    return true if onboarding_status.sequence_delivered_last.nil?
    sequence_index > onboarding_status.sequence_delivered_last
  end

  def deliver_campaign_email!
    Hello::EmailDrip.new(email_template_name, user, self.class.name).send
  end

  def mark_sequence_delivered!
    onboarding_status.update_attribute(:sequence_delivered_last, current_campaign_sequence)
  end
end
