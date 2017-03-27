describe PaymentMethod do
  it 'should soft-delete' do
    p = PaymentMethod.create
    expect(p.deleted_at).to be_nil
    p.destroy
    expect(p.deleted_at).to be_within(2).of(Time.current)
  end

  it 'should provide the current_payment_details if available' do
    p = PaymentMethod.create
    expect(p.current_details).to be_nil
    p.details << PaymentMethodDetails.new(data: { 'foo' => 'bar1' })
    expect(p.current_details.data['foo']).to eq('bar1')
    p.details << PaymentMethodDetails.new(data: { 'foo' => 'bar2' })
    expect(p.current_details.data['foo']).to eq('bar2')
  end

  it 'should provide all the payment_details in order created' do
    p = PaymentMethod.create
    p.details << PaymentMethodDetails.new(data: { 'foo' => 'bar1' })
    p.details << PaymentMethodDetails.new(data: { 'foo' => 'bar2' })
    expect(p.details.collect { |d| d.data['foo'] }).to eq(%w(bar1 bar2))
    p = PaymentMethod.find(p.id)
    expect(p.details.collect { |d| d.data['foo'] }).to eq(%w(bar1 bar2))
  end
end
