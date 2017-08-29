class SiteElements::Update < Less::Interaction
  expects :element
  expects :params

  def run
    SiteElement.transaction do
      change_type! if type_should_change?
      disable_use_question_if_template
      element.update_attributes!(params)
      destroy_previous_image_if_necessary
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

  def destroy_previous_image_if_necessary
    previous_image.destroy if previous_image && previous_image.site_elements.blank?
  end

  def previous_image
    @previous_image ||=
      begin
        return unless @element.previous_changes.include? 'active_image_id'

        old_image_id, _new_image_id = @element.previous_changes['active_image_id']
        ImageUpload.find(old_image_id)
      end
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
