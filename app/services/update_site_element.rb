class UpdateSiteElement
  def initialize(element, params)
    @element = element
    @params = params
    @theme_id = params[:theme_id]
    @new_type = params[:element_subtype]
  end

  def call
    SiteElement.transaction do
      @element = copy_element_and_change_type if type_should_change?
      disable_use_question_if_template
      element.update!(params)
      destroy_previous_image_if_necessary
    end
    element
  end

  private

  attr_reader :element, :params, :new_type, :theme_id

  def copy_element_and_change_type
    existing_element = element
    element_with_new_type.tap do
      existing_element.update!(paused: true)
    end
  end

  def element_with_new_type
    new_element = element.dup
    new_element.element_subtype = new_type
    copy_active_image_to(new_element)
    new_element
  end

  def copy_active_image_to(new_element)
    new_element.active_image = element.active_image
  end

  def destroy_previous_image_if_necessary
    previous_image.destroy if previous_image && previous_image.site_elements.blank?
  end

  def previous_image
    return unless element.previous_changes.include? 'active_image_id'

    @previous_image ||=
      begin
        old_image_id, _new_image_id = element.previous_changes['active_image_id']
        ImageUpload.find(old_image_id) if old_image_id
      end
  end

  def type_should_change?
    new_type.present? && new_type != element.element_subtype
  end

  def disable_use_question_if_template
    return unless (theme = Theme.find_by(id: theme_id))
    return unless theme.type == 'template'
    params[:use_question] = false
  end
end
