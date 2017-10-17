class ContactListsPage < PageObject
  self.page_url = ->(site) { site_contact_lists_path(site) }

  def lists
    find('table a').map do |element|
      {
        href: element.attrs['href'],
        name: element.text,
        element: element
      }
    end
  end

  def new_contact_list
    find('#new-contact-list').click
    ContactListModal.new
  end

  def connect_contact_list(provider, attrs)
    new_contact_list.tap do |modal|
      modal.connect_provider(provider, attrs)
    end
  end

  def open_list(name)
    lists.find { |list| list[:name] == name }
  end
end
