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

  it "sends an email as soon as it gets created" do
    # TODO: expect syntax
    MailerGateway.should_receive(:send_email) do |*args|
      args[0].should == 'Referal Invite Initial'
      args[1].should == "tj@hellobar.com"
      args[2][:referral_link].should =~ Regexp.new(Hellobar::Settings[:url_base])
      args[2][:referral_sender].should == @user.email
      args[2][:referral_body].should == @referral.body
    end

    @referral.set_standard_body
    @referral.state = 'sent'
    @referral.email = 'tj@hellobar.com'
    @referral.save!
  end

  it "is invalid if the email belongs to an existing user" do
    @referral.email = users(:wootie).email
    @referral.state = 'sent'
    @referral.should_not be_valid
  end
end
