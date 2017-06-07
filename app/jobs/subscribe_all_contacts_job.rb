class SubscribeAllContactsJob < ApplicationJob
  # proper name for the main_queue on the Edge server is `hb3_edge`, however
  # hellobar_backend servers are configured to send SQS messages into `hellobar_edge`,
  # so we need to use this name until we are able to reconfigure it at hellobar_backend.
  queue_as { Rails.env.edge? ? 'hellobar_edge' : "hb3_#{ Rails.env }" }

  def perform(contact_list)
    SubscribeAllContacts.new(contact_list).call
  end
end