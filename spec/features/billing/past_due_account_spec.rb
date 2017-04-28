require 'integration_helper'

feature 'Billing. Past due account', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, :with_rule, :pro, user: user) }
  given!(:bill) { create(:past_due_bill, subscription: site.current_subscription) }

  given!(:fake_data_api_original) { Hellobar::Settings[:fake_data_api] }

  before do
    Hellobar::Settings[:fake_data_api] = true
    login user
  end

  after do
    Hellobar::Settings[:fake_data_api] = fake_data_api_original
  end

  scenario 'displays notification about outstanding bill' do
    visit site_path(site)
    expect(page).to have_content "You have an outstanding bill for $#{ bill.amount.to_i }.00, " \
                                 "dated #{ bill.bill_at.strftime('%b %d, %Y') }. Fix this."
  end
end
