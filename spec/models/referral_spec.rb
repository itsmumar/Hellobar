require 'spec_helper'

describe Referral do
  fixtures :all
  before do
    @user = users(:joey)
    @referral = @user.referrals.build
  end

  it "can produce an invite body" do
    @referral.invitation_body.should match(@user.name)
  end

  it "has a url" do
    @referral.url.should match(users(:joey).referral_token)
  end
end
