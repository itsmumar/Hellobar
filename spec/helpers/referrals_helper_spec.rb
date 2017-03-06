require 'spec_helper'

describe ReferralsHelper do
  fixtures :all
  it 'Returns a URL' do
    user = users(:joey)
    url = helper.referral_url_for_user(user)

    expect(url).to be_a(String)
    expect(url).to match(user.referral_token.token)
  end

  it 'Returns an icon for a referral with a valid state' do
    ref = Referral.new(state: :sent)
    img = helper.icon_for_referral(ref)

    expect(img).to match('img')
    expect(img).to match('sent.svg')
  end

  it 'Returns an empty string for a referral with an empty state' do
    ref = Referral.new(state: nil)
    img = helper.icon_for_referral(ref)

    expect(img).to eq('')
  end

  it 'Returns the text for a referral with a valid state' do
    ref = Referral.new(state: :sent)
    text = helper.text_for_referral(ref)

    expect(text).to match(I18n.t('referral.state.sent'))
  end

  it 'Returns an empty string for a referral with an empty state' do
    ref = Referral.new(state: nil)
    text = helper.text_for_referral(ref)

    expect(text).to eq('')
  end
end
