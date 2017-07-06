class ContactListPage < PageObject
  self.page_url = ->(site, list) { site_contact_list_path(site, list) }

  def title
    find('.service-block .service-description').text
  end

  def edit_contact_list
    find('#edit-contact-list').click
    ContactListModal.new
  end
end
