class SendCampaignEmailSerializer < ActiveModel::Serializer
  attributes :fromName, :fromEmail, :subject, :body, :plain_body

  def body
    object.body + (object.site.sender_address.present? ?
        "<p style='background: #f9f9f9;padding: 10px; width: 100%; text-align: center; margin-top: 20px;'>
    #{ object.site.sender_address.address_one }  #{ object.site.sender_address.address_two },
    #{ object.site.sender_address.city }, #{ object.site.sender_address.state } #{ object.site.sender_address.postal_code },
    #{ object.site.sender_address.country }
    </p>" : '')
  end

  def plainBody
    object.plain_body
  end

  def fromName
    object.from_name
  end

  def fromEmail
    object.from_email
  end

end