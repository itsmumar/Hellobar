class SubscribeContactWorker
  include Shoryuken::Worker

  # proper name for the main_queue on the Edge server is `hb3_edge`, however
  # hellobar_backend servers are configured to send SQS messages into `hellobar_edge`,
  # so we need to use this name until we are able to reconfigure it at hellobar_backend.
  shoryuken_options queue: -> { Rails.env.edge? ? 'hellobar_edge' : "hb3_#{ Rails.env }" }
  shoryuken_options auto_delete: true, body_parser: self

  Contact = Struct.new(:id, :email, :fields) do
    def email
      cleanup(self[:email])
    end

    def fields
      cleanup(self[:fields])
    end

    def contact_list
      @contact_list ||= ContactList.find(id)
    end

    def cleanup(value)
      value.strip == 'nil' ? nil : value.presence&.strip
    end
  end

  # parse message like 'contact_list:sync_one[1,"email@example.com","firstname, lastname"]'
  def self.parse(body)
    data = body.match(/contact_list:sync_one\[(?<id>\d+),\s*"?(?<email>.*?)"?,\s*"?(?<fields>.*?)"?\]/)
    Contact.new(*data.captures) if data
  end

  def self.perform_now(body)
    new.subscribe(parse(body))
  end

  def perform(sqs_msg, contact)
    subscribe(contact)
  rescue => e
    Raven.capture_exception(e, extra: { arguments: [sqs_msg.body, contact], queue_name: sqs_msg.queue_name })
    sqs_msg.delete
  end

  def subscribe(contact)
    raise 'Cannot sync without email present' if contact.email.blank?
    SubscribeContact.new(contact).call
  end
end
