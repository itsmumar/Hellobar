class CampaignSerializer < ActiveModel::Serializer
  attributes :id, :name, :body, :subject,
    :from_email, :from_name, :sent_at, :archived_at,
    :site_id, :contact_list_id, :status, :statistics

  has_one :contact_list

  def site_id
    object.site.id
  end
end
