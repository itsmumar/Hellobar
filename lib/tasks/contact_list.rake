namespace :contact_list do
  desc 'Sync a single email to the remote service'
  task :sync_one, [:contact_list_id, :email, :name] => :environment do |_t, args|
    raise 'Cannot sync without email present' unless args[:email].present?

    ContactList.find(args[:contact_list_id]).tap do |list|
      list.sync_one! args[:email], args[:name]
    end
  end

  task :sync_all!, [:contact_list_id] => :environment do |_t, args|
    ContactList.find(args[:contact_list_id]).tap(&:sync_all!)
  end
end
