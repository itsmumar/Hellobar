require 'integration_helper'

feature "Trial User", js: true do
  before do
    @user = login
    @site = create(:site)
    @site.users << @user
    subscription = Subscription::Pro.new(schedule: "monthly")
    @site.change_subscription(subscription, nil, 90.day) # 90 day subscription
  end
  after { devise_reset }

  scenario "shows a button in the header that prompts user to enter payment" do
    visit site_path(@site)
    expect(page).to have_content('ENJOYING HELLO BAR PRO? CLICK HERE TO KEEP IT.')
  end
end
