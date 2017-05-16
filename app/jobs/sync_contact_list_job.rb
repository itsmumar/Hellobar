class SyncContactListJob < ApplicationJob
  # proper name for main_queue is `hb3_edge`, but this needs to be reconfigured at hellobar_backend
  queue_as { Rails.env.edge? ? 'hellobar_edge' : "hb3_#{ Rails.env }" }

  def perform(contact_list)
    SyncAllContactList.new(contact_list).call
  end
end
