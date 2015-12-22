require 'spec_helper'

describe ReferralsHelper do
  fixtures :all
  it "Returns a URL" do
    user = users(:joey)
    url = helper.referral_url_for_user(user)
    expect(url).to be_a(String)
    expect(url).to match(user.referral_token)
  end
end
