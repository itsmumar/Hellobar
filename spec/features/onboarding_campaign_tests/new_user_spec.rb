require 'integration_helper'
require 'email_integration_helper'

feature "New User Onboarding email campaigns" do
  given!(:user) { login }
  given(:email) { 'someone@somewhere.com' }
  given(:invitee) { User.find_or_invite_by_email(email, user.sites.first) }

  before do
    UserOnboardingStatusSetter.any_instance.stub(:in_campaign_ab_test?).and_return(true)
    record_mailer_gateway_request_history!
  end

  after do
    devise_reset
  end

  xscenario "user bails on creating their first bar" do
    the_onboarding_campaigns_run

    expect_user_to_only_recieve(user, "Drip Campaign: Create a bar")
  end

  xscenario "user picks a goal for a bar but does not configure it", :js do
    page.find(".global-sidebar form .button").click
    page.all(".goal-block .button").to_a.first.click

    the_onboarding_campaigns_run

    expect_user_to_only_recieve(user, "Drip Campaign: Configure your bar")
  end

  xscenario "user added to an existing site" do
    user.sites.first.site_memberships.create!(user: invitee, role: "admin")

    the_onboarding_campaigns_run

    expect_user_to_only_recieve(user, "Drip Campaign: Create a bar")
    expect_no_email(invitee)
  end

end
