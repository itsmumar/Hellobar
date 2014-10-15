class SubscriptionSerializer < ActiveModel::Serializer
  attributes :schedule, :type

  def schedule
    object.values[:schedule]
  end

  def type
    object.values[:name].downcase
  end
end
