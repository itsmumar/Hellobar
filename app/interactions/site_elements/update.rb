class SiteElements::Update < Less::Interaction
  expects :element
  expects :params

  def run
    SiteElement.transaction do
      change_type! if type_should_change?
      disable_use_question_if_template
      element.update_attributes!(params)
    end
    true
  rescue ActiveRecord::ActiveRecordError, ActiveRecord::RecordInvalid
    false
  end

  private

  def change_type!
    existing_element = @element
    new_element = element_with_new_type

    existing_element.update! paused: true

    @element = new_element
  end

  def new_type
    @new_type ||= params.delete(:element_subtype)
  end

  def element_with_new_type
    new_element = @element.dup
    new_element.element_subtype = new_type
    copy_active_image_to(new_element)
    new_element
  end

  def copy_active_image_to(new_element)
    new_element.active_image = @element.active_image
  end

  def type_should_change?
    new_type.present? && new_type != @element.element_subtype
  end

  def disable_use_question_if_template
    return unless (theme = Theme.find(params[:theme_id]))
    return unless theme.type == 'template'
    params[:use_question] = false
  end
end
