class AddReferralTokenToSite < ActiveRecord::Migration
  def change
    add_column :sites, :referral_token, :string
    Site.reset_column_information
    Site.find_each { |site| site.save }
  end
end
