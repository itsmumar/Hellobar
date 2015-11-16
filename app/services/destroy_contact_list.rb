class DestroyContactList
  SITE_ELEMENTS_ACTIONS = { keep: 0, delete: 1 }

  attr_reader :contact_list, :site

  delegate :errors, to: :contact_list

  def initialize(contact_list)
    @contact_list = contact_list
    @site = contact_list.site
  end

  def valid?
    @contact_list.errors.empty?
  end

  def destroy(site_elements_action = nil)
    validate!(site_elements_action)

    return false unless valid?

    handle_site_elements(site_elements_action)
    @contact_list.destroy
  end

  private

  def validate!(action)
    unless valid_site_elements_action?(action)
      @contact_list.errors.add(
        :base,
        "Must specify an action for existing bars, modals, sliders, and takeovers"
      )
    end
  end

  def has_site_elements?
    contact_list.site_elements_count > 0
  end

  def valid_site_elements_action?(action)
    !has_site_elements? ||
      SITE_ELEMENTS_ACTIONS.values.include?(action.to_i)
  end

  def keep_site_elements?(action)
    action == SITE_ELEMENTS_ACTIONS[:keep]
  end

  def handle_site_elements(action)
    action = action.to_i

    if has_site_elements? && keep_site_elements?(action)
       reset_site_elements_contact_list
    end
  end

  def reset_site_elements_contact_list
    new_list = site.contact_lists.create(name: 'My Contacts')
    elements = contact_list.site_elements

    elements.each do |element|
      element.update_attributes(contact_list_id: new_list.id)
    end
  end
end
