require 'integration_helper'

feature "User onboarding statuses get updated as they select a goal for their first Hello Bar" do

  before do
    # initialize the environment in the necessary order before testing
    user
    goals
  end
  after { devise_reset }

  let(:user) {login}
  let(:goals) do
    page.find(".global-sidebar form .button").click
    page.all(".goal-block").collect{|block|block['data-route']}
  end
  let(:onboarding_status_setter) do
    UserOnboardingStatusSetter.new(user, true, UserOnboardingStatus.none)
  end

  scenario "Each goal click is tracked", js: true, dd: true do
    User.any_instance.stub(:onboarding_status_setter) {onboarding_status_setter}

    expect(goals.size > 1).to be_true
    expect(onboarding_status_setter).to receive(:selected_goal!).exactly(goals.size).times
    click_through_all_goal_interstitial_options
  end

  def click_through_all_goal_interstitial_options
    goals.each do |goal|
      wait_for_ajax
      button = first(".goal-block[data-route='#{goal}'] .button")
      unless button
        sleep 0.5
        first(".goal-block[data-route='#{goal}'] .button").click
      end
      button.click
      page.driver.go_back

      if page.has_button?('Create New')
        page.click_button('Create New')
      end
    end
  end
end
