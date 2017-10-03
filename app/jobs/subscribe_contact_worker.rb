class SubscribeContactWorker
  include Shoryuken::Worker

  shoryuken_options queue: "hb3_#{ Rails.env }"
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
  rescue StandardError => e
    Raven.capture_exception(e, extra: { arguments: [sqs_msg.body, contact], queue_name: sqs_msg.queue_name })
    sqs_msg.delete
  end

  def subscribe(contact)
    raise 'Cannot sync without email present' if contact.email.blank?
    SubscribeContact.new(contact).call
  end
end
