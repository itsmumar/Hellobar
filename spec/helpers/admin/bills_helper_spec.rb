describe Admin::BillsHelper do
  describe '#bill_actions' do
    context 'when bill is pending' do
      let(:bill) { create(:bill, :pending) }

      it 'renders pay bill links' do
        expect(helper.bill_actions(bill)).to include(pay_admin_bill_path(bill))
      end

      it 'renders void bill links' do
        expect(helper.bill_actions(bill)).to include(void_admin_bill_path(bill))
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill)).not_to include(refund_admin_bill_path(bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill)).not_to include(chargeback_admin_bill_path(bill))
      end
    end

    context 'when bill is failed' do
      let(:bill) { create(:bill, :failed) }

      it 'renders pay bill links' do
        expect(helper.bill_actions(bill)).to include(pay_admin_bill_path(bill))
      end

      it 'renders void bill links' do
        expect(helper.bill_actions(bill)).to include(void_admin_bill_path(bill))
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill)).not_to include(refund_admin_bill_path(bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill)).not_to include(chargeback_admin_bill_path(bill))
      end
    end

    context 'when bill is paid' do
      let(:bill) { create(:bill, :pro, :paid) }

      it 'renders refund bill links' do
        expect(helper.bill_actions(bill)).to include(refund_admin_bill_path(bill))
      end

      it 'renders chargeback bill links' do
        expect(helper.bill_actions(bill)).to include(chargeback_admin_bill_path(bill))
      end

      it 'does not render pay bill links' do
        expect(helper.bill_actions(bill)).not_to include(pay_admin_bill_path(bill))
      end

      it 'does not render void bill links' do
        expect(helper.bill_actions(bill)).not_to include(void_admin_bill_path(bill))
      end
    end

    context 'when bill is refunded' do
      let(:bill) { create(:bill, :pro, :paid) }

      before do
        stub_cyber_source :refund
        RefundBill.new(bill).call
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill)).not_to include(refund_admin_bill_path(bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill)).not_to include(chargeback_admin_bill_path(bill))
      end

      it 'does not render pay bill links' do
        expect(helper.bill_actions(bill)).not_to include(pay_admin_bill_path(bill))
      end

      it 'does not render void bill links' do
        expect(helper.bill_actions(bill)).not_to include(void_admin_bill_path(bill))
      end
    end

    context 'when bill is chargedback' do
      let(:bill) { create(:bill, :paid, :paid) }

      before do
        stub_cyber_source :refund
        ChargebackBill.new(bill).call
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill)).not_to include(refund_admin_bill_path(bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill)).not_to include(chargeback_admin_bill_path(bill))
      end

      it 'does not render pay bill links' do
        expect(helper.bill_actions(bill)).not_to include(pay_admin_bill_path(bill))
      end

      it 'does not render void bill links' do
        expect(helper.bill_actions(bill)).not_to include(void_admin_bill_path(bill))
      end
    end
  end
end
