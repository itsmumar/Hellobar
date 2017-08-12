class CreditCardSerializer < ActiveModel::Serializer
  attributes :id, :current_details
  attributes :data

  def current_details
    data
  end

  def to_hash
    {
      id: id,
      current_details: current_details
    }
  end

  def data
    {
      id: object.id,
      number: object.number,
      expiration: expiration,
      name: name,
      city: object.billing_address.city,
      state: object.billing_address.state,
      zip: object.billing_address.zip,
      address: object.billing_address.address,
      country: object.billing_address.country
    }
  end

  def expiration
    "#{ object.month }/#{ object.year }"
  end

  def name
    "#{ object.first_name } #{ object.last_name }"
  end
end
