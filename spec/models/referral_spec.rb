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

  it "is invalid if the email belongs to an existing user" do
    @referral.email = users(:wootie).email
    @referral.state = 'sent'
    @referral.should_not be_valid
  end

  it "has a URL once it gets saved and has a token" do
    expect(@referral.url).to be_empty
    @referral.email = 'random@email.com'
    @referral.state = 'sent'
    @referral.save!
    expect(@referral.url).not_to be_empty
    expect(@referral.url).to match @referral.referral_token.token
  end
end
