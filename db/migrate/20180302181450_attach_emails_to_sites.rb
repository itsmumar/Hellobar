class AttachEmailsToSites < ActiveRecord::Migration
  class ContactListModel < ActiveRecord::Base
    self.table_name = :contact_lists
  end

  class CampaignModel < ActiveRecord::Base
    self.table_name = :campaigns

    belongs_to :contact_list, class_name: 'ContactListModel'
  end

  class EmailModel < ActiveRecord::Base
    self.table_name = :emails

    has_one :campaign, class_name: 'CampaignModel', foreign_key: :email_id
  end

  def up
    add_column :emails, :site_id, :integer, after: :id

    EmailModel.includes(campaign: :contact_list).find_each do |email|
      email.update(site_id: email.campaign&.contact_list&.site_id)
    end
  end

  def down
    remove_column :emails, :site_id
  end
end
