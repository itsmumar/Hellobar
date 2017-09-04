require 'integration_helper'
require 'email_integration_helper'

feature 'One User In all onboarding Campaigns' do
  before(:each) { Timecop.freeze(start) }
  after(:each)  { Timecop.return }

  before { allow_any_instance_of(UserOnboardingStatusSetter).to receive(:in_campaign_ab_test?).and_return(true) }
  before { record_mailer_gateway_request_history! }

  let(:start)      { Time.zone.now }
  let(:start_date) { start.to_date }
  let!(:user) { login }

  def transition_user_through_onboarding(operating_user)
    repeatedly_time_travel_and_run_onboarding_campaigns(2)

    operating_user.onboarding_status_setter.selected_goal!
    repeatedly_time_travel_and_run_onboarding_campaigns(2)

    operating_user.onboarding_status_setter.created_element!
    repeatedly_time_travel_and_run_onboarding_campaigns

    operating_user.onboarding_status_setter.installed_script!
    repeatedly_time_travel_and_run_onboarding_campaigns
  end

  def repeatedly_time_travel_and_run_onboarding_campaigns(days = 12)
    travel_and_run_onboardign_campaigns(1.second)
    travel_and_run_onboardign_campaigns(10.minutes)
    Timecop.travel(- 10.minutes - 1.second)

    days.times do
      travel_and_run_onboardign_campaigns(1.day)
    end
  end

  def travel_and_run_onboardign_campaigns(travel_time)
    Timecop.travel(travel_time)
    the_onboarding_campaigns_run
  end

  feature 'users excluded from the onboarding campaign a/b tests' do
    let(:excluded_user) do
      allow_any_instance_of(UserOnboardingStatusSetter).to receive(:in_campaign_ab_test?).and_return(false)
      login
    end

    scenario 'do not receive email from the campaigns' do
      transition_user_through_onboarding(excluded_user)
      expect_no_email(excluded_user)
    end
  end

  feature 'with a/b testing including the user in all campaigns' do
    before { transition_user_through_onboarding(user) }

    scenario "the user receives the 'Create a bar' on day 0" do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq(['CreateABar'])
    end

    scenario 'the user does not receive email on day 1' do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq([])
    end

    scenario "the user receives the 'Configure your bar' on day 2" do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq(['ConfigureYourBar'])
    end

    scenario 'the user does not receive email on day 3' do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq([])
    end
  end
end
