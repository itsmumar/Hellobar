describe BillsHelper do
  describe '#coupons_and_uses' do
    it 'yields a list of coupons and uses' do
      coupon = create :coupon, :referral
      bill = create(:bill, :pro)
      3.times { bill.coupon_uses.create(coupon: coupon) }
      run_coupon = ->(b) { helper.coupons_and_uses(bill, &b) }

      expect(run_coupon).to yield_with_args(coupon, 3)
      expect(run_coupon).to yield_control.once
    end
  end

  describe '#coupon_label' do
    it 'displays a nice coupon label' do
      coupon = build_stubbed :coupon, :referral
      label = helper.coupon_label(coupon, 3)

      expect(label).to include(coupon.label)
      expect(label).to include('&times; 3')
      expect(label).to include(helper.number_to_currency(coupon.amount))
    end
  end

  describe '#coupon_discount' do
    it 'displays a discount' do
      coupon = build_stubbed :coupon, :referral
      label = helper.coupon_discount(coupon, 3)

      expect(label).to include(helper.number_to_currency(coupon.amount * -3))
    end
  end

  describe '#bill_address_info' do
    context 'when invoice information is present' do
      it 'displays billing address from invoice information' do
        site = build_stubbed :site, :with_invoice_information

        bill_address_info = helper.bill_address_info(site, nil)

        site.invoice_information.split.each do |invoice_part|
          expect(bill_address_info).to include invoice_part
        end
      end
    end

    context 'when no invoice information is present' do
      it 'displays billing address from CyberSource' do
        address = double 'Address',
          state: 'CA', country: 'USA', zip: '90210',
          city: 'Los Anageles', address1: nil

        details = double 'Details', billing_address: address

        site = build_stubbed :site

        bill_address_info = helper.bill_address_info(site, details)

        expect(bill_address_info).to include address.state
        expect(bill_address_info).to include address.country
        expect(bill_address_info).to include address.zip
        expect(bill_address_info).to include address.city
      end
    end
  end
end
