require 'spec_helper'

describe Referrals::Create do
  fixtures :all

  before :each do
    @user = users(:joey)
  end

  it 'sends an email when we ask it to' do
    expect(MailerGateway).to receive :send_email do |*args|
      expect(args[0]).to eq 'Referal Invite Initial'
      expect(args[1]).to eq 'tj@hellobar.com'
      expect(args[2][:referral_link]).to match Regexp.new(Hellobar::Settings[:url_base])
      expect(args[2][:referral_sender]).to eq @user.name
      expect(args[2][:referral_body]).to eq 'test body'
    end

    Referrals::Create.run(
      sender: @user,
      params: {email: 'tj@hellobar.com', body: 'test body'},
      send_emails: true
    )
  end

  it 'does not send an email when we ask it not to' do
    expect(MailerGateway).not_to receive :send_email
    Referrals::Create.run(
      sender: @user,
      params: {email: 'tj@hellobar.com', body: 'test body'},
      send_emails: false
    )
  end
end