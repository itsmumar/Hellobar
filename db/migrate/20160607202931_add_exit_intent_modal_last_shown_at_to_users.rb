class AddExitIntentModalLastShownAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :exit_intent_modal_last_shown_at, :datetime
  end
end
