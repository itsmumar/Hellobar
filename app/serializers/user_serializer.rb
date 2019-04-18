class UserSerializer < ActiveModel::Serializer
  attributes :status, :first_name, :last_name, :stripe_customer_id
end
