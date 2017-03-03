require 'spec_helper'

describe PaymentMethod do
  it 'should soft-delete' do
    p = PaymentMethod.create
    p.deleted_at.should be_nil
    p.destroy
    p.deleted_at.should be_within(2).of(Time.now)
  end

  it 'should provide the current_payment_details if available' do
    p = PaymentMethod.create
    p.current_details.should be_nil
    p.details << PaymentMethodDetails.new(data: {'foo'=>'bar1'})
    p.current_details.data['foo'].should == 'bar1'
    p.details << PaymentMethodDetails.new(data: {'foo'=>'bar2'})
    p.current_details.data['foo'].should == 'bar2'
  end

  it 'should provide all the payment_details in order created' do
    p = PaymentMethod.create
    p.details << PaymentMethodDetails.new(data: {'foo'=>'bar1'})
    p.details << PaymentMethodDetails.new(data: {'foo'=>'bar2'})
    p.details.collect{|d| d.data['foo']}.should == %w{bar1 bar2}
    p = PaymentMethod.find(p.id)
    p.details.collect{|d| d.data['foo']}.should == %w{bar1 bar2}
  end
end
