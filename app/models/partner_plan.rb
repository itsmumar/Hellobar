class PartnerPlan
  include ActiveModel::Model

  attr_accessor :id, :subscription_type, :duration, :name

  cattr_accessor :all

  def self.find(id)
    all.find { |plan| plan.id == id }
  end

  def subscription_name
    subscription_type.humanize
  end
end

PartnerPlan.all = [
  PartnerPlan.new(id: 'growth_30', subscription_type: 'growth', duration: 30, name: '30 days free Growth trial'),
  PartnerPlan.new(id: 'growth_60', subscription_type: 'growth', duration: 60, name: '60 days free Growth trial'),
  PartnerPlan.new(id: 'growth_90', subscription_type: 'growth', duration: 90, name: '90 days free Growth trial')
]
