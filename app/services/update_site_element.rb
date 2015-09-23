class UpdateSiteElement
  attr_reader :element, :orig_element

  def initialize(element)
    @orig_element = element
  end

  def update(params = {})
    attrs = params.dup
    new_type = attrs.delete(:element_subtype)

    if type_change?(new_type)
      new_element = dup_element_with_type(new_type)
      @element = new_element
    else
      @element = orig_element
    end

    begin
      SiteElement.transaction do
        @element.update_attributes!(attrs)
        disable_original! if type_change?(new_type)
      end
    rescue ActiveRecord::ActiveRecordError
      return false
    end

    @element.site.generate_script
    true
  end

  def dup_element_with_type(new_type)
    new_element = orig_element.dup
    new_element.element_subtype = new_type
    new_element
  end

  private

  def type_change?(new_type)
    new_type.present? && new_type != orig_element.element_subtype
  end

  def disable_original!
    @orig_element.paused = true
    @orig_element.save!
  end
end
