module ConditionInputHelper
  extend ActionView::Helpers::TagHelper
  extend ActionView::Helpers::FormTagHelper

  def self.build_date_name(condition_form)
    "#{condition_form.input(:value).match(/name\="(.+)"/)[1]}"
  end

  def self.start_date_field(condition_form=nil)
    return date_field_tag :value, nil, disabled: true, class: 'start_date value form-control' unless condition_form

    value = condition_form.object.kind_of?(DateCondition) ? condition_form.object.value[:start_date] : nil
    name = "#{build_date_name(condition_form)}[start_date]"

    condition_form.date_field :value, { name: name, value: value, disabled: true, class: 'start_date value form-control' }
  end

  def self.end_date_field(condition_form=nil)
    return date_field_tag :value, nil, disabled: true, clas: 'end_date value form-control' unless condition_form

    value = condition_form.object.kind_of?(DateCondition) ? condition_form.object.value[:end_date] : nil
    name = "#{build_date_name(condition_form)}[end_date]"

    condition_form.date_field :value, { name: name, value: value, disabled: true, class: 'end_date value form-control' }
  end

  def self.url_field(condition_form=nil)
    return text_field_tag :value, nil, disabled: true, class: 'url value form-control' unless condition_form
    value = condition_form.object.kind_of?(UrlCondition) ? condition_form.object.value : nil

    condition_form.text_field :value, { value: value, disabled: true, class: 'url value form-control' }
  end

  def self.country_field(condition_form=nil)
    return select_tag :value, nil, disabled: true, class: 'country value form-control', include_blank: false unless condition_form
    value = condition_form.object.kind_of?(CountryCondition) ? condition_form.object.value : nil

    condition_form.input_field :value, collection: ['USA', 'USA', 'USA'], value: value, disabled: true, class: 'country value form-control', include_blank: false
  end

  def self.device_field(condition_form=nil)
    return select_tag :value, nil, disabled: true, class: 'device value form-control', include_blank: false unless condition_form
    value = condition_form.object.kind_of?(DeviceCondition) ? condition_form.object.value : nil

    condition_form.input_field :value, collection: ['Desktop', 'Mobile'], value: value, disabled: true, class: 'device value form-control', include_blank: false
  end
end
