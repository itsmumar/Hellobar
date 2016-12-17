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
    page.find('.global-sidebar form').click_button('Create New')
    page.all(".goal-block").collect{|block| block['data-route']}
  end
  let(:onboarding_status_setter) do
    UserOnboardingStatusSetter.new(user, true, UserOnboardingStatus.none)
  end

  scenario "Each goal click is tracked", js: true, dd: true do
    User.any_instance.stub(:onboarding_status_setter) {onboarding_status_setter}
    expect(goals.size > 1).to be_true

    # As "Others" is not a goal actually, avoid tracking expectation for "Others" goal.
    expect(onboarding_status_setter).to receive(:selected_goal!).exactly(goals.size - 1).times
    click_through_all_goal_interstitial_options
    visit site_path user.sites.first
  end

  def click_through_all_goal_interstitial_options
    page.driver.browser.manage.window.maximize

    goals.each_with_index do |goal, ind|
      button = page.first(".goal-block[data-route='#{goal}']").find_link('Select This Goal')
      builder = page.driver.browser.action
      builder.key_down(:control)
      builder.click(button.native) if button
      builder.key_up(:control)
      builder.perform
    end
  end
end
