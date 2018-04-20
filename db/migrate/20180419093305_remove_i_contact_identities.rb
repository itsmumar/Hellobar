class RemoveIContactIdentities < ActiveRecord::Migration
  def up
    Identity.where(provider: 'icontact').destroy_all
  end
end
