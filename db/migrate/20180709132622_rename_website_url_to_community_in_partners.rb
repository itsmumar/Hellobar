class RenameWebsiteURLToCommunityInPartners < ActiveRecord::Migration
  def change
    rename_column :partners, :website_url, :community

    reversible do |dir|
      dir.up do
        execute "UPDATE partners SET community = ''"
      end
    end
  end
end
