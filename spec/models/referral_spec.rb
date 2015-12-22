require 'spec_helper'

describe Referral do
  fixtures :all
  before do
    @user = users(:joey)
    @referral = @user.sent_referrals.build
  end

  it "has no body set by default" do
    @referral.body.should be_nil
  end

  it "has a standard body that can be set explicitly" do
    @referral.set_standard_body

    expect(@referral.body).to include(@user.name)
  end

  it "has a url" do
    expect(@referral.url).to include(users(:joey).referral_token)
  end
end
