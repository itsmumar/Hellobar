class UpdateContactList
  def initialize(contact_list, params)
    @contact_list = contact_list
    @params = params
  end

  def call
    destroy_identity_if_needed
    contact_list.update_attributes(params)
  end

  private

  attr_reader :contact_list, :params

  def destroy_identity_if_needed
    return if contact_list.identity.nil? || identity_has_more_lists? || params[:identity] == contact_list.identity

    contact_list.identity.destroy
  end

  def identity_has_more_lists?
    contact_list.identity.contact_lists.where.not(id: contact_list.id).exists?
  end
end
