class SendCampaignEmailSerializer < ActiveModel::Serializer
  attributes :fromName, :fromEmail, :subject, :body, :plainBody

  def body
    object.body + (object.campaign.email.preview_text.present? ?
        "<span class='preheader' style='color: transparent; display: none; height: 0; max-height: 0; max-width: 0;
    opacity: 0; overflow: hidden; mso-hide: all; visibility: hidden; width: 0;'>#{object.campaign.email.preview_text}</span>" : '')

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
