describe Referrals::Create do
  let(:user) { create(:user) }

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
    expect(ReferralsMailer)
      .to receive(:invite)
      .with(instance_of(Referral))
      .and_return double(deliver_later: true)

    Referrals::Create.run(
      sender: user,
      params: { email: 'tj@hellobar.com', body: 'test body' },
      send_emails: true
    )
  end

  it 'does not send an email when we ask it not to' do
    expect(ReferralsMailer).not_to receive :invite

    Referrals::Create.run(
      sender: user,
      params: { email: 'tj@hellobar.com', body: 'test body' },
      send_emails: false
    )
  end

  it 'tracks "referred_friend" event' do
    expect(TrackEvent)
      .to receive_service_call
      .with(:referred_friend, user: user, referral: instance_of(Referral))

    Referrals::Create.run(
      sender: user,
      params: { email: 'tj@hellobar.com', body: 'test body' },
      send_emails: false
    )
  end

  context 'when trying to send 11th invitation' do
    before { create_list :referral, 10, sender: user }

    it 'raises Error' do
      expect {
        Referrals::Create.run(
          sender: user,
          params: { email: 'tj@hellobar.com', body: 'test body' },
          send_emails: false
        )
      }.to raise_error Referrals::Create::Error,
        "Only #{ Referrals::Create::NUMBER_OF_ALLOWED_REFERRALS } invitations are allowed per day"
    end
  end
end
