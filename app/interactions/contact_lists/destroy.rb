module ContactLists
  SITE_ELEMENTS_ACTIONS = { keep: 0, delete: 1 }.with_indifferent_access
end

class ContactLists::Destroy < Less::Interaction
  expects :contact_list
  expects :site_elements_action, allow_nil: true

  def run
    return false unless validate!

    reset_site_elements_contact_list if reset_contact_lists?

    destroy_contact_list
    true
  end

  private

  def site
    @site ||= contact_list.site
  end

  def validate!
    unless valid_site_elements_action?
      @contact_list.errors.add(
        :base,
        'Must specify an action for existing bars, modals, sliders, and takeovers'
      )
      return false
    end

    true
  end

  def reset_contact_lists?
    site_elements? && keep_site_elements?
  end

  def site_elements?
    contact_list.site_elements_count > 0
  end

  def keep_site_elements?
    site_elements_action.to_i == ContactLists::SITE_ELEMENTS_ACTIONS[:keep]
  end

  def valid_site_elements_action?
    !site_elements? ||
      ContactLists::SITE_ELEMENTS_ACTIONS.values.include?(site_elements_action.to_i)
  end

  def destroy_contact_list
    contact_list.reload.destroy
  end

  def reset_site_elements_contact_list
    new_list = site.contact_lists.create(name: 'My Contacts')
    elements = contact_list.site_elements

    elements.each do |element|
      element.update_attributes(contact_list_id: new_list.id)
    end
  end
end
