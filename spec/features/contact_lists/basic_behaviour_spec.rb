require 'integration_helper'

feature 'Basic behaviour', :js, :contact_list_feature do
  let(:provider) { 'aweber' }
  let!(:user) { create :user }
  let!(:site) { create :site, :with_bars, user: user }

  before do
    sign_in user
  end

  scenario 'deletes orphaned identities' do
    connect

    expect(page).to have_content('Disconnect AWeber')

    expect(Identity.last).to be_a(Identity)
    expect(Identity.last.provider).to eql 'aweber'

    page.find('footer .button.cancel').click

    wait_for_ajax
    expect(Identity.last).to be_nil
  end

  private

  def connect
    connect_to_provider(site, provider)
  end
end
