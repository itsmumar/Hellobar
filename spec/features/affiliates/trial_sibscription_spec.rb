describe 'Affiliate trial subscription', js: true do
  let(:user) { create(:user, :affiliate) }

  before do
    create(:partner, affiliate_identifier: user.affiliate_identifier, partner_plan_id: 'growth_90')
    sign_in user
  end

  it 'adds 90 days of trial on Growth subscription when user creates a site', freeze: '2018-06-24T14:00 UTC' do
    visit new_site_path

    fill_in 'site[url]', with: 'mysite.com'
    click_on 'Create Site'

    expect(page).to have_content "I'll create it later"
    click_on "I'll create it later - take me back"

    expect(page).to have_content 'Settings'
    click_on 'Settings'

    expect(page).to have_content 'Enjoying Hello Bar Growth?'
    expect(page).to have_content 'This site is on a trial plan. Please enter credit card details by 2018-09-22'
  end
end
