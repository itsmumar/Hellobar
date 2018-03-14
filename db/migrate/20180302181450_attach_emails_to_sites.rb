class AttachEmailsToSites < ActiveRecord::Migration
  def up
    add_column :emails, :site_id, :integer, after: :id, null: false

    Campaign.unscoped.each do |campaign|
      campaign.email.update!(site_id: campaign.contact_list.site_id)
    end
  end

  def down
    remove_column :emails, :site_id
  end
end
