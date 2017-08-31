describe ReferralsMailer do
  describe '#invite' do
    let(:referral) { create :referral }
    let(:mail) { ReferralsMailer.invite referral }

    let(:subject) { "#{ referral.sender.name } has invited you to try Hello Bar" }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [referral.email]
      expect(mail.from).to eq ['contact@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match referral.body
      expect(mail.body.encoded).to include referral.url
      expect(mail.body.encoded).to match referral.expiration_date_string
    end
  end

  describe '#second_invite' do
    let(:referral) { create :referral }
    let(:mail) { ReferralsMailer.second_invite referral }

    let(:subject) { "#{ referral.sender.name }'s invitation is about to expire" }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [referral.email]
      expect(mail.from).to eq ['contact@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match referral.sender.name
      expect(mail.body.encoded).to include referral.url
      expect(mail.body.encoded).to match referral.expiration_date_string
    end
  end

  describe '#successful' do
    let(:referral) { create :referral }
    let(:user) { create :user }
    let(:mail) { ReferralsMailer.successful referral, user }

    let(:subject) { 'You Just Got a Free Bonus Month of Hello Bar Pro!' }

    it 'renders the headers' do
      expect(mail.subject).to eq subject
      expect(mail.to).to eq [referral.sender.email]
      expect(mail.from).to eq ['contact@hellobar.com']
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match referral.sender.first_name
      expect(mail.body.encoded).to match user.name
      expect(mail.body.encoded).to match 'https://hellobar.com/referrals/new'
    end
  end
end
