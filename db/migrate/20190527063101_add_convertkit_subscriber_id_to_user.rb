class AddConvertkitSubscriberIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :convortkit_subscriber_id, :string
  end
end
