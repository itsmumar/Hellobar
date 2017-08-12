class CreditCardSerializer < ActiveModel::Serializer
  attributes :id, :name, :number, :expiration, :city, :state, :zip, :address, :country

  def expiration
    "#{ object.month }/#{ object.year }"
  end

  def name
    "#{ object.first_name } #{ object.last_name }"
  end
end
