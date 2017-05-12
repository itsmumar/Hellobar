class SyncContactListJob < ApplicationJob
  queue_as { Settings.main_queue }

  def perform(contact_list)
    contact_list.sync_all!
  end
end
