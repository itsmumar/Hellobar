class PaymentMethodDetailsSerializer < ActiveModel::Serializer
  attributes :data

  def data
    return {} unless object

    object.data ||= {}

    {
      id: object.id,
      payment_method_id: object.payment_method_id,
      number: object.data['number'],
      expiration: expiration,
      name: name,
      verification_value: object.data['verification_value'],
      city: object.data['city'],
      state: object.data['state'],
      zip: object.data['zip'],
      address: object.data['address1'],
      country: object.data['country']
    }
  end

  def expiration
    "#{ object.data['month'] }/#{ object.data['year'] }"
  end

  def name
    "#{ object.data['first_name'] } #{ object.data['last_name'] }"
  end
end
