class SyncOneContactListWorker
  include Shoryuken::Worker

  # proper name for main_queue is `hb3_edge`, but this needs to be reconfigured at hellobar_backend
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

  def perform(sqs_msg, contact)
    raise 'Cannot sync without email present' if contact.email.blank?

    SyncOneContactList.new(contact).call
  rescue => e
    Raven.capture_exception(e)
    sqs_msg.delete
  end
end
