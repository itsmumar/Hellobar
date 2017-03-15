require 'spec_helper'

describe Referrals::SendSecondEmail do
  let(:user) { create(:user) }
  let(:email) { 'user@hellobar.com' }
  let!(:referral) { create(:referral, sender: user, state: :sent, email: email) }

  it 'will send the email under normal circumstances' do
    expect(MailerGateway).to receive :send_email do |name, email, params|
      expect(name).to eq 'Referal Invite Second'
      expect(email).to eq email
      expect(params[:referral_link]).to include('http://hellobar.com/referrals/accept')
      expect(params[:referral_sender]).to eq user.name
    end

    Referrals::SendSecondEmail.run(referral: referral)
  end

  it "will not send the email for a referral that's been accepted" do
    expect(MailerGateway).not_to receive :send_email
    referral.state = 'signed_up'

    Referrals::SendSecondEmail.run(referral: referral)
  end

  it 'will not send the email for a referral that has a recipient' do
    expect(MailerGateway).not_to receive :send_email

    referral.recipient = create(:user)
    Referrals::SendSecondEmail.run(referral: referral)
  end

  it "will not send the email for a referral that's too old" do
    expect(MailerGateway).not_to receive :send_email

    referral.created_at = (Referral::FOLLOWUP_INTERVAL + 1.day).ago
    Referrals::SendSecondEmail.run(referral: referral)
  end
end
