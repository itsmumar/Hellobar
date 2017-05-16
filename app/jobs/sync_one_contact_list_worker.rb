class SyncOneContactListWorker
  include Shoryuken::Worker

  shoryuken_options queue: 'hellobar_test', auto_delete: true, body_parser: self

  Contact = Struct.new(:id, :email, :fields) do
    def email
      self[:email].strip == 'nil' ? nil : self[:email].presence&.strip
    end

    def fields
      self[:fields].strip == 'nil' ? nil : self[:fields].presence&.strip
    end

    def contact_list
      @contact_list ||= ContactList.find(id)
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
