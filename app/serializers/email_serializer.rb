class EmailSerializer < ActiveModel::Serializer
  attributes :id, :from_name, :from_email, :subject, :body, :plain_body
end
