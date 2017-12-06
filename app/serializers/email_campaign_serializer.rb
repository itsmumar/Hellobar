class EmailCampaignSerializer < ActiveModel::Serializer
  attributes :id, :name, :body, :subject,
    :from_email, :from_name, :sent_at, :site_id, :status

  has_one :contact_list
end
