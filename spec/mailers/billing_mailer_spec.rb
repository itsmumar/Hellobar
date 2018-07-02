describe BillingMailer do
  let(:credit_card) { create :credit_card }
  let(:site) { create :site }
  let(:bill) { ChangeSubscription.new(site, { subscription: 'pro' }, credit_card).call }
  let(:owner1) { create :user }
  let(:owner2) { create :user }

  before { site.owners = [owner1, owner2] }
  before { stub_cyber_source :purchase }

  describe '#could_not_charge' do
    let(:mail) { BillingMailer.could_not_charge(bill) }

    it 'renders the headers' do
      expect(mail.subject)
        .to eq("We could not charge your Visa ending in #{ credit_card.last_digits } for your Hello Bar subscription")
      expect(mail.to).to eq([owner1.email])
      expect(mail.cc).to eq([owner2.email])
      expect(mail.from).to eq(['contact@hellobar.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Hi')
    end
  end

  describe '#no_credit_card' do
    let(:mail) { BillingMailer.no_credit_card(bill) }

    it 'renders the headers' do
      expect(mail.subject).to eq('No credit card on file to renew your Hello Bar subscription')
      expect(mail.to).to eq([owner1.email])
      expect(mail.cc).to eq([owner2.email])
      expect(mail.from).to eq(['contact@hellobar.com'])
    end

    it 'renders the body' do
      expect(mail.body.encoded).to match('Hi')
    end
  end
end
