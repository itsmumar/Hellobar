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

    expect(page).to have_content('Upgrade Plan')
    expect(site.reload.current_subscription).to be_a(Subscription::Free)
  end

  scenario "downgrade to free from pro should say when it's active until" do
    # In the middle of an AB test.  Make sure we use the original
    allow_any_instance_of(ApplicationController).to receive(:get_ab_variation).and_return("original")

    site = @user.sites.first
    payment_method = create(:payment_method, user: @user)
    site.change_subscription(Subscription::Pro.new(schedule: 'monthly'), payment_method)
    end_date = site.current_subscription.active_until
    visit edit_site_path(site)
    click_link("Change plan or billing schedule")
    find(".different-plan").click
    basic_plan = find(".package-block.basic")
    basic_plan.find(".button").click
    expect(page).to have_content "until #{end_date.strftime("%-m-%-d-%Y")}"
  end
end
