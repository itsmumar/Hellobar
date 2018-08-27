class AddWarningOneEmailSentToSites < ActiveRecord::Migration
  def change
    add_column :sites, :warning_email_one_sent, :boolean, default: false
    add_column :sites, :warning_email_two_sent, :boolean, default: false
    add_column :sites, :warning_email_three_sent, :boolean, default: false
    add_column :sites, :limit_email_sent, :boolean, default: false
  end
end
