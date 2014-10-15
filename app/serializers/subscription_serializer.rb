class SubscriptionSerializer < ActiveModel::Serializer
  attributes :schedule, :type, :yearly_amount, :monthly_amount

  def schedule
    object.values[:schedule]
  end

  def type
    object.values[:name].downcase
  end

  def yearly_amount
    object.values[:yearly_amount]
  end

  def monthly_amount
    object.values[:monthly_amount]
  end
end
