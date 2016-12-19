require 'integration_helper'
require 'email_integration_helper'

feature "New User Onboarding email campaigns" do
  before do
    UserOnboardingStatusSetter.any_instance.stub(:in_campaign_ab_test?).and_return(true)
    record_mailer_gateway_request_history!
  end
  let!(:user)         {login}
  let(:invited_user)  {User.find_or_invite_by_email(Faker::Internet.email, user.sites.first)}

  after { devise_reset }

  scenario "user bails on creating their first bar" do
    the_onboarding_campaigns_run
    expect_user_to_only_recieve(user, "Drip Campaign: Create a bar")
  end

  scenario "user picks a goal for a bar but does not configure it", js: true do
    page.find(".global-sidebar form .button").click
    page.all(".goal-block .button").to_a.first.click

    the_onboarding_campaigns_run
    expect_user_to_only_recieve(user, "Drip Campaign: Configure your bar")
  end

  scenario "user added to an existing site" do
    user.sites.first.site_memberships.create!(user: invited_user, role: "admin")

    the_onboarding_campaigns_run
    expect_user_to_only_recieve(user, "Drip Campaign: Create a bar")
    expect_no_email(invited_user)
  end

end
