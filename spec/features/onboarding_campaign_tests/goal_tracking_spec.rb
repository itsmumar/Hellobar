require 'integration_helper'

feature "User onboarding statuses get updated as they select a goal for their first Hello Bar" do

  before do
    stub_out_get_ab_variations("Forced Email Path 2016-03-28", "Onboarding Limitted To Three Goals 2016-05-11") {"original"}
    # initialize the environment in the necessary order before testing
    user
    goals
  end
  after { devise_reset }

  let(:user) {login}
  let(:goals) do
    page.find(".global-sidebar form .button").click
    page.all(".goal-interstitial h6").collect{|header| header.text}
  end
  let(:onboarding_status_setter) do
    UserOnboardingStatusSetter.new(user,true, UserOnboardingStatus.none)
  end

  scenario "Each goal click is tracked", js: true, dd: true do
    User.any_instance.stub(:onboarding_status_setter) {onboarding_status_setter}

    expect(goals.size > 1).to be_true
    expect(onboarding_status_setter).to receive(:selected_goal!).exactly(goals.size).times
    click_through_all_goal_interstitial_options
  end

  def click_through_all_goal_interstitial_options
    goals.each do |goal|
      page.find(:xpath, "//h6[contains(text(),'#{goal}')]/following-sibling::button").click
      page.driver.go_back
      page.find(".global-sidebar form .button").click
    end
  end

end
