class FetchContactsCSV
  def initialize(contact_list)
    @contact_list = contact_list
  end

  def call
    CSV.generate do |csv|
      csv << %w[Email Fields Subscribed\ At]
      fetch_contacts.each do |contact|
        csv << [contact.email, contact.name, contact.subscribed_at.to_s]
      end
    end
  end

  private

  attr_reader :contact_list

  def fetch_contacts
    FetchAllContacts.new(contact_list).call
  end
end
