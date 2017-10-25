class UserOnboardingStatusSetter
  include Hello::InternalAnalytics

  attr_reader :user, :is_paying, :onboarding_statuses

  def initialize(user, is_paying, onboarding_statuses)
    @user = user
    @is_paying = is_paying
    @onboarding_statuses = onboarding_statuses
  end

  def in_campaign_ab_test?(test_name)
    ab_variation_or_nil(test_name, user) == 'campaign'
  end

  def new_user!
    create_status_if_able!(:new)
  end

  def created_site!
    create_status_if_able!(:created_site, 'Configure Your Bar Reminder New Users Only 2016-03-28')
  end

  def selected_goal!
    create_status_if_able!(:selected_goal, 'Configure Your Bar Reminder New Users Only 2016-03-28')
  end

  def created_element!
    create_status_if_able!(:created_element)
  end

  def installed_script!
    create_status_if_able!(:installed_script)
  end

  def uninstalled_script!
    create_status_if_able!(:created_element)
  end

  def bought_subscription!
    create_status_if_able!(:bought_subscription)
  end

  private

  def create_status_if_able!(new_status, ab_test = nil, sequence_delivered_last = nil)
    return unless can_enter_status?(new_status, ab_test)
    user.onboarding_statuses.create!(status_id: UserOnboardingStatus::STATUSES[new_status],
                                     sequence_delivered_last: sequence_delivered_last)
  end

  def can_enter_status?(new_status, ab_test = nil)
    return false if ab_test.present? && !in_campaign_ab_test?(ab_test)
    return false unless active_for_onboarding_campaigns? || new_status == :new

    case new_status
    when :new
      onboarding_statuses.empty? && # don't re-add users to the new status
        independant_user? # don't onboard users who were invited to the site by another user

    when :created_site, :selected_goal
      status_is_progressing?(new_status)

    when :created_element
      (
        status_is_progressing?(new_status) ||
        (recent_status(:installed) && recent_status(:created_element))
      )

    when :installed_script
      status_is_progressing?(new_status) &&
        !is_paying

    when :bought_subscription
      status_is_progressing?(new_status) &&
        is_paying

    else
      false
    end
  end

  def status_is_progressing?(new_status_name)
    UserOnboardingStatus::STATUSES[new_status_name] > onboarding_statuses.first.status_id
  end

  def active_for_onboarding_campaigns?
    onboarding_statuses.with_status(:new).any?
  end

  def recent_status(status_name)
    onboarding_statuses.with_status(status_name).first
  end

  def independant_user?
    user.status != User::TEMPORARY
  end
end
