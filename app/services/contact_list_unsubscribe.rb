class ContactListUnsubscribe
  def initialize(contact_list)
    @contact_list = contact_list
  end

  def call
    update_contact_list
  end

  private

  attr_reader :contact_list

  def update_contact_list
    contact_list.update!(data: {}, identity: nil) && contact_list
  end
end
