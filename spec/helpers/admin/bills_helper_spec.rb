describe Admin::BillsHelper do
  describe '#bill_actions' do
    let(:site) { create(:site) }
    let(:subscription) { create(:subscription, :pro, site: site) }

    context 'when bill is pending' do
      let(:bill) { create(:bill, :pending, subscription: subscription) }

      it 'renders pay bill links' do
        expect(helper.bill_actions(bill, site)).to include(pay_admin_site_bill_path(site, bill))
      end

      it 'renders void bill links' do
        expect(helper.bill_actions(bill, site)).to include(void_admin_site_bill_path(site, bill))
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(refund_admin_site_bill_path(site, bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(chargeback_admin_site_bill_path(site, bill))
      end
    end

    context 'when bill is failed' do
      let(:bill) { create(:bill, :failed, subscription: subscription) }

      it 'renders pay bill links' do
        expect(helper.bill_actions(bill, site)).to include(pay_admin_site_bill_path(site, bill))
      end

      it 'renders void bill links' do
        expect(helper.bill_actions(bill, site)).to include(void_admin_site_bill_path(site, bill))
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(refund_admin_site_bill_path(site, bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(chargeback_admin_site_bill_path(site, bill))
      end
    end

    context 'when bill is paid' do
      let(:bill) { create(:bill, :paid, subscription: subscription) }

      it 'renders refund bill links' do
        expect(helper.bill_actions(bill, site)).to include(refund_admin_site_bill_path(site, bill))
      end

      it 'renders chargeback bill links' do
        expect(helper.bill_actions(bill, site)).to include(chargeback_admin_site_bill_path(site, bill))
      end

      it 'does not render pay bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(pay_admin_site_bill_path(site, bill))
      end

      it 'does not render void bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(void_admin_site_bill_path(site, bill))
      end
    end

    context 'when bill is refunded' do
      let(:bill) { create(:bill, :paid, subscription: subscription) }

      before do
        stub_cyber_source :refund
        RefundBill.new(bill).call
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(refund_admin_site_bill_path(site, bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(chargeback_admin_site_bill_path(site, bill))
      end

      it 'does not render pay bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(pay_admin_site_bill_path(site, bill))
      end

      it 'does not render void bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(void_admin_site_bill_path(site, bill))
      end
    end

    context 'when bill is chargedback' do
      let(:bill) { create(:bill, :paid, subscription: subscription) }

      before do
        stub_cyber_source :refund
        ChargebackBill.new(bill).call
      end

      it 'does not render refund bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(refund_admin_site_bill_path(site, bill))
      end

      it 'does not render chargeback bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(chargeback_admin_site_bill_path(site, bill))
      end

      it 'does not render pay bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(pay_admin_site_bill_path(site, bill))
      end

      it 'does not render void bill links' do
        expect(helper.bill_actions(bill, site)).not_to include(void_admin_site_bill_path(site, bill))
      end
    end
  end
end
