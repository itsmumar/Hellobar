class UpdateSiteElement
  def initialize(element, params, current_user)
    @element = element
    @theme = Theme.find_by(id: params[:theme_id])
    @params = disable_use_question_if_template(params)
    @new_type = params[:element_subtype]
    @current_user = current_user
  end

  def call
    SiteElement.transaction do
      @element = copy_element_and_change_type if type_should_change?
      element.update!(params)
      destroy_previous_image_if_necessary
      track_event
    end
    generate_script
    element
  end

  private

  attr_reader :element, :params, :new_type, :theme, :current_user

  def generate_script
    element.site.script.generate
  end

  def copy_element_and_change_type
    existing_element = element
    element_with_new_type.tap do
      existing_element.pause!
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
    previous_image.destroy if previous_image&.site_elements&.empty?
  end

  def previous_image
    return unless element.previous_changes.include? 'active_image_id'
    old_image_id, _new_image_id = element.previous_changes['active_image_id']
    find_image(old_image_id)
  rescue ActiveRecord::RecordNotFound
    element.errors.add(:base, 'Previous image could not be found')
    raise ActiveRecord::RecordInvalid, element
  end

  def find_image(old_image_id)
    @previous_image ||= ImageUpload.find(old_image_id) if old_image_id
  end

  def type_should_change?
    new_type.present? && new_type != element.element_subtype
  end

  def disable_use_question_if_template(params)
    params[:use_question] = false if theme&.type == 'template'
    params
  end

  def track_event
    TrackEvent.new(:updated_bar, site_element: element, user: current_user).call
  end
end
