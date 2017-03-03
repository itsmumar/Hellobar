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
    payment_form.first_name.should == 'Bill'
  end

  it 'returns nil for the first name when name is not present' do
    data[:name] = nil

    payment_form.first_name.should be_nil
  end

  it 'returns the last name' do
    payment_form.last_name.should == 'Middle Namerson'
  end

  it 'returns nil for the last name when name is not present' do
    data[:name] = nil

    payment_form.last_name.should be_nil
  end

  it 'returns a blank string for the last name when only the first name is present' do
    data[:name] = 'Bob'

    payment_form.last_name.should be_blank
  end

  it 'returns the month' do
    payment_form.month.should == 8
  end

  it 'returns the raw epxiration when the month cant be parsed' do
    data[:expiration] = '1.2'

    payment_form.month.should == '1.2'
  end

  it 'returns the year' do
    payment_form.year.should == 2016
  end

  it 'accepts mm/yy format' do
    data[:expiration] = '08/16'
    form = PaymentForm.new(data)
    form.year.should == 2016
  end

  it 'accepts mm/yyyy format' do
    data[:expiration] = '08/2016'
    form = PaymentForm.new(data)
    form.year.should == 2016
  end

  it 'returns the raw expiration when the year cant be parsed' do
    data[:expiration] = '1.2'

    payment_form.year.should == '1.2'
  end

  it 'returns the proper hash' do
    payment_form.to_hash.should == {
      :number => '12345',
      :month => 8,
      :year => 2016,
      :first_name => 'Bill',
      :last_name => 'Middle Namerson',
      :verification_value => '123',
      :city => 'Chicago',
      :state => 'IL',
      :zip => '60647',
      :address1 => '2423 W. North Ave',
      :country => 'USA'
    }
  end
end
