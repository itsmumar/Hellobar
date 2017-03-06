class SiteElements::Update < Less::Interaction
  expects :element
  expects :params

  def run
    SiteElement.transaction do
      change_type! if type_should_change?
      element.update_attributes!(params)
    end
    true
  rescue ActiveRecord::ActiveRecordError
    false
  end

  private

  def change_type!
    existing_element = element
    new_element = element_with_new_type

    existing_element.paused = true
    existing_element.save!

    @element = new_element
  end

  def new_type
    @new_type ||= params.delete(:element_subtype)
  end

  def element_with_new_type
    new_element = @element.dup
    new_element.element_subtype = new_type
    new_element
  end

  def type_should_change?
    new_type.present? && new_type != @element.element_subtype
  end
end
