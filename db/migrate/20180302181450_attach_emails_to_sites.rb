class AttachEmailsToSites < ActiveRecord::Migration
  def up
    add_column :emails, :site_id, :integer, after: :id

    Campaign.reset_column_information

    Campaign.unscoped.each do |campaign|
      campaign.email.update!(site_id: campaign.contact_list.site_id)
    end

    change_column_null :emails, :site_id, false
  end

  def down
    remove_column :emails, :site_id
  end
end
