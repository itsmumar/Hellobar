class UpdateContact
  def initialize(contact_list, email, params)
    @contact_list = contact_list
    @email = email
    @params = params
  end

  def call
    delete_contact
    create_contact
  end

  private

  attr_reader :contact_list, :email, :params

  def delete_contact
    DeleteContact.new(contact_list, email).call
  end

  def create_contact
    PutContact.new(contact_list, params).call
  end
end
