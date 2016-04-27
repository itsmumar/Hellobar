require 'integration_helper'
require 'email_integration_helper'

feature "New Users Upgrade Hello Bar Drip Campaign" do
  after { devise_reset }
  let(:user) {login}

  scenario "user receives the first email in this campaign" do
    UserOnboardingStatusSetter.any_instance.stub(:in_campaign_ab_test?).and_return(true)
    Timecop.freeze(Time.zone.today - 2) do
      user
    end

    UserOnboardingStatus.create!(user_id: user.id, status_id: UserOnboardingStatus::STATUSES[:installed_script])

    record_mailer_gateway_request_history!
    the_onboarding_campaigns_run
    expect_user_to_only_recieve(user, "Drip Campaign: Upgrade 1")
  end

end
