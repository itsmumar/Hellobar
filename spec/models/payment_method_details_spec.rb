describe PaymentMethodDetails do
  let(:details) { build :payment_method_details }

  it 'is read-only' do
    d = PaymentMethodDetails.create
    expect { d.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { d.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  describe '#name' do
    specify { expect { details.name }.to raise_error(NameError) }
  end

  describe '#charge' do
    specify { expect { details.charge(100) }.to raise_error(NameError) }
  end

  describe '#refund' do
    specify { expect { details.refund(100, 'id') }.to raise_error(NameError) }
  end
end
