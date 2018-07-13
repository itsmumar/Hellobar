describe Partner do
  subject { build(:partner) }

  it { is_expected.to validate_presence_of(:affiliate_identifier) }
  it { is_expected.to validate_uniqueness_of(:affiliate_identifier) }
  it { is_expected.to validate_presence_of(:partner_plan) }

  it { is_expected.to allow_value('abc@example.com').for(:email) }
  it { is_expected.not_to allow_value('example').for(:email) }
  it { is_expected.not_to allow_value('@example').for(:email) }

  describe '.default_partner_plan' do
    it 'is free 30 days of Growth' do
      plan = Partner.default_partner_plan

      expect(plan.subscription_type).to eql 'growth'
      expect(plan.duration).to eql 30
    end
  end
end
