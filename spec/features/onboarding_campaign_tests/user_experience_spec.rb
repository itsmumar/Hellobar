require 'integration_helper'
require 'email_integration_helper'

feature "One User In all onboarding Campaigns" do

  before(:each) {Timecop.freeze(start)}
  after(:each)  {Timecop.return}

  before {UserOnboardingStatusSetter.any_instance.stub(:in_campaign_ab_test?).and_return(true)}
  before {record_mailer_gateway_request_history!}

  let(:start)      {Time.zone.now}
  let(:start_date) {start.to_date}
  let!(:user)       {login}

  after { devise_reset }

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

  feature "users excluded from the onboarding campaign a/b tests" do
    let(:excluded_user) do
      UserOnboardingStatusSetter.any_instance.stub(:in_campaign_ab_test?).and_return(false)
      login
    end

    scenario "do not receive email from the campaigns" do
      transition_user_through_onboarding(excluded_user)
      expect_no_email(excluded_user)
    end
  end

  feature "with a/b testing including the user in all campaigns" do
    before {transition_user_through_onboarding(user)}

    scenario "the user receives the 'Create a bar' on day 0" do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq(["Drip Campaign: Create a bar"])
    end

    scenario "the user does not receive email on day 1" do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq([])
    end

    scenario "the user receives the 'Configure your bar' on day 2" do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq(["Drip Campaign: Configure your bar"])
    end

    scenario "the user does not receive email on day 3" do
      expect(email_received_a_number_of_days_after(user, start_date)).to eq([])
    end

    scenario "the user receives the Install campaign email" do
      {
        4 => ["Drip Campaign: Install 1"],
        5 => ["Drip Campaign: Install 2"],
        6 => ["Drip Campaign: Install 3"],
        7 => ["Drip Campaign: Install 4"],
        8 => [],
        9 => ["Drip Campaign: Install 5"],
        10 => [],
        11 => [],
        12 => ["Drip Campaign: Install 6"],
        13 => [],
        14 => ["Drip Campaign: Install 7"],
        15 => []
      }.each do |index, email|
        expect(email_received_a_number_of_days_after(user, start_date, index)).to eq(email)
      end
    end

    scenario "the user receives the Upgrade campaign email" do
      {
        16 => ["Drip Campaign: Upgrade 1"],
        17 => ["Drip Campaign: Upgrade 2"],
        18 => ["Drip Campaign: Upgrade 3"],
        19 => ["Drip Campaign: Upgrade 4"],
        20 => ["Drip Campaign: Upgrade 5"],
        21 => ["Drip Campaign: Upgrade 6"],
        22 => ["Drip Campaign: Upgrade 7"],
        23 => ["Drip Campaign: Upgrade 8"],
        24 => []
      }.each do |index, email|
        expect(email_received_a_number_of_days_after(user, start_date, index)).to eq(email)
      end
    end
  end

  feature "with more than one site" do
    before do
      create(:site_ownership, user: user)
      transition_user_through_onboarding(user)
    end

    scenario "the user receives the Upgrade campaign email with an extra 9th email" do
      {
        16 => ["Drip Campaign: Upgrade 1"],
        17 => ["Drip Campaign: Upgrade 2"],
        18 => ["Drip Campaign: Upgrade 3"],
        19 => ["Drip Campaign: Upgrade 4"],
        20 => ["Drip Campaign: Upgrade 5"],
        21 => ["Drip Campaign: Upgrade 6"],
        22 => ["Drip Campaign: Upgrade 7"],
        23 => ["Drip Campaign: Upgrade 8"],
        24 => ["Drip Campaign: Upgrade 9"],
        25 => []
      }.each do |index, email|
        expect(email_received_a_number_of_days_after(user, start_date, index)).to eq(email)
      end
    end
  end

end
