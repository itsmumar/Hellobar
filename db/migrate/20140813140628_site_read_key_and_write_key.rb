class SiteReadKeyAndWriteKey < ActiveRecord::Migration
  def change
    # NOTE: These will need to be generated as random unique 40-digit hexdigests
    add_column :sites, :read_key, :string, default: nil
    add_column :sites, :write_key, :string, default: nil
  end
end
