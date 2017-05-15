class SyncContactListJob < ApplicationJob
  queue_as Settings.main_queue

  def perform(contact_list)
    SyncAllContactList.new(contact_list).call
  end
end
