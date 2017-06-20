describe Subscription do
  it { is_expected.to validate_presence_of :schedule }
  it { is_expected.to validate_presence_of :site }

  describe '#period' do
    context 'when monthly' do
      let(:subscription) { build(:subscription, schedule: 'monthly') }

      specify 'returns 1.month when monthly' do
        expect(subscription.period).to eql 1.month
      end
    end

    context 'when yearly' do
      let(:subscription) { build(:subscription, schedule: 'yearly') }

      specify 'returns 1.year when monthly' do
        expect(subscription.period).to eql 1.year
      end
    end
  end

  describe '#initialize' do
    context 'Free' do
      let(:subscription) { build :subscription, :free }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql 25_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql nil
      end
    end

    context 'FreePlus' do
      let(:subscription) { build :subscription, :free_plus }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql 25_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql nil
      end
    end

    context 'Pro' do
      let(:subscription) { build :subscription, :pro }

      it 'sets initial values' do
        expect(subscription.amount).to eql 15
        expect(subscription.visit_overage).to eql 250_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 5
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :pro, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 149 }
      end
    end

    context 'ProComped' do
      let(:subscription) { build :subscription, :pro_comped }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql 250_000
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql 0
      end
    end

    context 'ProManaged' do
      let(:subscription) { build :subscription, :pro_managed }

      it 'sets initial values' do
        expect(subscription.amount).to eql 0
        expect(subscription.visit_overage).to eql nil
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql nil
      end
    end

    context 'Enterprise' do
      let(:subscription) { build :subscription, :enterprise }

      it 'sets initial values' do
        expect(subscription.amount).to eql 99
        expect(subscription.visit_overage).to eql nil
        expect(subscription.visit_overage_unit).to eql nil
        expect(subscription.visit_overage_amount).to eql nil
      end

      context 'when yearly' do
        let(:subscription) { build :subscription, :enterprise, schedule: 'yearly' }

        specify { expect(subscription.amount).to eql 999 }
      end
    end
  end
end
