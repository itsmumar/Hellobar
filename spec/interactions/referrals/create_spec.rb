describe Referrals::Create do
  let(:user) { create(:user) }
  let(:hellobar_host) { Hellobar::Settings[:host] }

  it 'gets created with a site id selected if the user has one site' do
    ownership = create(:site_membership)

    ref = Referrals::Create.run(
      sender: ownership.user.reload,
      params: { email: 'tj@hellobar.com', body: 'test body' },
      send_emails: true
    )

    expect(ref.site_id).not_to be_nil
  end

  it 'sends an email when we ask it to' do
    expect(MailerGateway).to receive :send_email do |name, email, params|
      expect(name).to eq 'Referral Invite Initial'
      expect(email).to eq 'tj@hellobar.com'
      expect(params[:referral_link]).to match Regexp.new("http://#{ hellobar_host }/referrals/accept")
      expect(params[:referral_sender]).to eq user.name
      expect(params[:referral_body]).to eq 'test body'
    end

    Referrals::Create.run(
      sender: user,
      params: { email: 'tj@hellobar.com', body: 'test body' },
      send_emails: true
    )
  end

  it 'does not send an email when we ask it not to' do
    expect(MailerGateway).not_to receive :send_email
    Referrals::Create.run(
      sender: user,
      params: { email: 'tj@hellobar.com', body: 'test body' },
      send_emails: false
    )
  end
end
