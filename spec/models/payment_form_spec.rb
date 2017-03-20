require 'spec_helper'

describe PaymentForm do
  let(:data) do
    {
      name: 'Bill Middle Namerson',
      expiration: '08/2016',
      number: '12345',
      verification_value: '123',
      city: 'Chicago',
      state: 'IL',
      zip: '60647',
      address: '2423 W. North Ave',
      country: 'USA'
    }
  end

  let(:payment_form) { PaymentForm.new(data) }

  it 'returns the first name' do
    expect(payment_form.first_name).to eq('Bill')
  end

  it 'returns nil for the first name when name is not present' do
    data[:name] = nil

    expect(payment_form.first_name).to be_nil
  end

  it 'returns the last name' do
    expect(payment_form.last_name).to eq('Middle Namerson')
  end

  it 'returns nil for the last name when name is not present' do
    data[:name] = nil

    expect(payment_form.last_name).to be_nil
  end

  it 'returns a blank string for the last name when only the first name is present' do
    data[:name] = 'Bob'

    expect(payment_form.last_name).to be_blank
  end

  it 'returns the month' do
    expect(payment_form.month).to eq(8)
  end

  it 'returns the raw epxiration when the month cant be parsed' do
    data[:expiration] = '1.2'

    expect(payment_form.month).to eq('1.2')
  end

  it 'returns the year' do
    expect(payment_form.year).to eq(2016)
  end

  it 'accepts mm/yy format' do
    data[:expiration] = '08/16'
    form = PaymentForm.new(data)
    expect(form.year).to eq(2016)
  end

  it 'accepts mm/yyyy format' do
    data[:expiration] = '08/2016'
    form = PaymentForm.new(data)
    expect(form.year).to eq(2016)
  end

  it 'returns the raw expiration when the year cant be parsed' do
    data[:expiration] = '1.2'

    expect(payment_form.year).to eq('1.2')
  end

  it 'returns the proper hash' do
    expect(payment_form.to_hash).to eq(
      number: '12345',
      month: 8,
      year: 2016,
      first_name: 'Bill',
      last_name: 'Middle Namerson',
      verification_value: '123',
      city: 'Chicago',
      state: 'IL',
      zip: '60647',
      address1: '2423 W. North Ave',
      country: 'USA'
    )
  end
end
