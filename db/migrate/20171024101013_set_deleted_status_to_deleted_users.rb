class SetDeletedStatusToDeletedUsers < ActiveRecord::Migration
  def up
    User.deleted.update_all status: User::DELETED
  end
end
