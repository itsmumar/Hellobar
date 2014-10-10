class SiteSerializer < ActiveModel::Serializer
  attributes :id, :url, :contact_lists

  has_many :rules, serializer: RuleSerializer

  def contact_lists
    object.contact_lists.map do |list|
      {
        :id => list.id,
        :name => list.name
      }
    end
  end
end
