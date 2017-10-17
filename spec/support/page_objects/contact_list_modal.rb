class ContactListModal < PageObject
  def selected_list
    option = find('#contact_list_remote_list_id').all('option').find(&:selected?)
    option&.text
  end

  def selected_tags
    find_all('.contact-list-tag')
      .flat_map { |el| el.all('option').select(&:selected?).map(&:text) }
      .delete_if { |text| text == 'Select ...' }
  end

  def connect_provider(provider, attrs)
    view_all_tools
    choose_provider(provider)
    assign_attributes attrs
    connect
  end

  def view_all_tools
    page.find('span', text: 'View all tools').click
  end

  def choose_provider(provider)
    page.find(".#{ provider }-provider").click
  end

  def connect
    page.find('.button.ready').click
  end

  def done
    page.find('.button.submit').click
    ContactListPage.new
  end

  def tags=(tags)
    tags.each do |tag|
      find('select.contact-list-tag').select(tag)
      find('a[data-js-action="add-tag"]').click
    end
  end

  def list=(value)
    page.find('select#contact_list_remote_list_id').select(value)
  end

  def username=(value)
    page.find(:fillable_field, 'contact_list[data][username]').set value
  end

  def api_key=(value)
    page.find(:fillable_field, 'contact_list[data][api_key]').set value
  end
end
