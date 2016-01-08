require 'integration_helper'

feature "Payment modal interaction", js: true do
  before { @user = login }
  after { devise_reset }

  scenario "downgrade to free from pro" do
    # In the middle of an AB test.  Make sure we use the original
    allow_any_instance_of(ApplicationController).to receive(:get_ab_variation).and_return("original")

    site = @user.sites.first
    site.change_subscription(Subscription::ProComped.new(schedule: 'monthly'))
    visit edit_site_path(site)
    click_link("Upgrade plan")
    basic_plan = find(".package-block.basic")
    basic_plan.find(".button").click
    click_link("Downgrade")

    expect(site.reload.current_subscription).to be_a(Subscription::Free)
  end

end
