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
end
