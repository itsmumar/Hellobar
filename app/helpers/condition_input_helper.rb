module ConditionInputHelper
  extend ActionView::Helpers::TagHelper
  extend ActionView::Helpers::FormTagHelper

  def self.build_date_name(simple_form)
    "#{simple_form.input(:value).match(/name\="(.+)"/)[1]}"
  end

  def self.start_date_field(simple_form=nil)
    return date_field_tag :value, nil, disabled: true, class: 'start_date value form-control' unless simple_form

    value = simple_form.object.kind_of?(DateCondition) ? simple_form.object.value[:start_date] : nil
    name = "#{build_date_name(simple_form)}[start_date]"

    simple_form.date_field :value, { name: name, value: value, disabled: true, class: 'start_date value form-control' }
  end

  def self.end_date_field(simple_form=nil)
    return date_field_tag :value, nil, disabled: true, clas: 'end_date value form-control' unless simple_form

    value = simple_form.object.kind_of?(DateCondition) ? simple_form.object.value[:end_date] : nil
    name = "#{build_date_name(simple_form)}[end_date]"

    simple_form.date_field :value, { name: name, value: value, disabled: true, class: 'end_date value form-control' }
  end

  def self.url_field(simple_form=nil)
    return text_field_tag :value, nil, disabled: true, class: 'url value form-control' unless simple_form
    value = simple_form.object.kind_of?(UrlCondition) ? simple_form.object.value : nil

    simple_form.text_field :value, { value: value, disabled: true, class: 'url value form-control' }
  end

  def self.country_field(simple_form=nil)
    return select_tag :value, nil, disabled: true, class: 'country value form-control', include_blank: false unless simple_form
    value = simple_form.object.kind_of?(CountryCondition) ? simple_form.object.value : nil

    simple_form.input_field :value, collection: ['USA', 'USA', 'USA'], value: value, disabled: true, class: 'country value form-control', include_blank: false
  end

  def self.device_field(simple_form=nil)
    return select_tag :value, nil, disabled: true, class: 'device value form-control', include_blank: false unless simple_form
    value = simple_form.object.kind_of?(DeviceCondition) ? simple_form.object.value : nil

    simple_form.input_field :value, collection: ['Desktop', 'Mobile'], value: value, disabled: true, class: 'device value form-control', include_blank: false
  end
end
