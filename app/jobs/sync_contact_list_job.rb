class SyncContactListJob < ApplicationJob
  queue_as { Rails.env.edge? ? 'hellobar_edge' : "hb3_#{ Rails.env }" }

  def perform(contact_list)
    SyncAllContactList.new(contact_list).call
  end
end
