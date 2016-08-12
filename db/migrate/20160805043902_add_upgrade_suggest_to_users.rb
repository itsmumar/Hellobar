class AddUpgradeSuggestToUsers < ActiveRecord::Migration
  def change
    add_column :users, :upgrade_suggest_modal_last_shown_at, :datetime
  end
end
