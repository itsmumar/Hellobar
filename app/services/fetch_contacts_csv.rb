class FetchContactsCSV
  def initialize(contact_list)
    @contact_list = contact_list
  end

  def call
    CSV.generate do |csv|
      csv << %w[Email Fields Subscribed\ At]
      fetch_contacts.each do |row|
        csv << [row[:email], row[:name], row[:subscribed_at].to_s]
      end
    end
  end

  private

  attr_reader :contact_list

  def fetch_contacts
    FetchContacts::All.new(contact_list).call
  end
end
