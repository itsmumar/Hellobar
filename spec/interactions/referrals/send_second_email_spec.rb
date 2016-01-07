require 'spec_helper'

describe Referrals::SendSecondEmail do
  fixtures :all
  before :each do
    @user = users(:joey)
    @email = Faker::Internet.email
    @referral = create(:referral, sender: @user, state: 'sent', email: @email)
  end

  it "will send the email under normal circumstances" do
    expect(MailerGateway).to receive :send_email do |*args|
      expect(args[0]).to eq 'Referal Invite Second'
      expect(args[1]).to eq @email
      expect(args[2][:referral_link]).to match Regexp.new(Hellobar::Settings[:url_base])
      expect(args[2][:referral_sender]).to eq @user.name
    end

    Referrals::SendSecondEmail.run(referral: @referral)
  end

  it "will not send the email for a referral that's been accepted" do
    expect(MailerGateway).not_to receive :send_email
    @referral.state = "signed_up"

    Referrals::SendSecondEmail.run(referral: @referral)
  end

  it 'will not send the email for a referral that has a recipient' do
    expect(MailerGateway).not_to receive :send_email

    @referral.recipient = users(:wootie)
    Referrals::SendSecondEmail.run(referral: @referral)
  end

  it "will not send the email for a referral that's too old" do
    expect(MailerGateway).not_to receive :send_email

    @referral.created_at = (Referral::EXPIRES_INTERVAL + 1.day).ago
    Referrals::SendSecondEmail.run(referral: @referral)
  end
end