class RemoveAccountIdFromInternalPeople < ActiveRecord::Migration
  def change
    remove_column :internal_people, :account_id
  end
end
