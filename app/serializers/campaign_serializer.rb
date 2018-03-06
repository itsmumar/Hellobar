class CampaignSerializer < ActiveModel::Serializer
  attributes :id, :name, :sent_at, :archived_at, :site_id, :contact_list_id, :status, :statistics, :email_id

  has_one :contact_list
  has_one :email

  def site_id
    object.site.id
  end
end
