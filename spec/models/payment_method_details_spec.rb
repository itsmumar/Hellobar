describe PaymentMethodDetails do
  let(:details) { build :payment_method_details }

  it 'is read-only' do
    d = PaymentMethodDetails.create
    expect { d.save }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { d.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
