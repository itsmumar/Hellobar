describe PromotionalPlan do
  it 'is 30 days of Growth subscription' do
    promotional_plan = PromotionalPlan.new

    expect(promotional_plan.subscription_type).to eql 'growth'
    expect(promotional_plan.duration).to eql 30
  end
end
