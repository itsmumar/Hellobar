require 'integration_helper'

feature 'Billing. Past due account', :js do
  given(:user) { create(:user) }
  given(:site) { create(:site, :with_rule, :pro, user: user) }
  given!(:bill) { create(:past_due_bill, subscription: site.current_subscription) }

  before do
    allow(Settings).to receive(:fake_data_api).and_return true

    login user
  end

  scenario 'displays notification about outstanding bill' do
    visit site_path(site)
    expect(page).to have_content "You have an outstanding bill for $#{ bill.amount.to_i }.00, " \
                                 "dated #{ bill.bill_at.strftime('%b %d, %Y') }. Fix this."
  end
end
