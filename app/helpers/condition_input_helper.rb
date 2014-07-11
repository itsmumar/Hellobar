module ConditionInputHelper
  def self.start_date_field(simple_form)
    value = simple_form.object.kind_of?(DateCondition) ? simple_form.object.value[:start_date] : nil
    name = "#{simple_form.input(:value).match(/name\="(.+)"/)[1]}['start_date']"

    simple_form.date_field :value, { name: name, value: value, disabled: true, class: 'start_date value' }
  end

  def self.end_date_field(simple_form)
    value = simple_form.object.kind_of?(DateCondition) ? simple_form.object.value[:end_date] : nil
    name = "#{simple_form.input(:value).match(/name\="(.+)"/)[1]}['end_date']"

    simple_form.date_field :value, { name: name, value: value, disabled: true, class: 'end_date value' }
  end

  def self.url_field(simple_form)
    value = simple_form.object.kind_of?(UrlCondition) ? simple_form.object.value : nil

    simple_form.text_field :value, { value: value, disabled: true, class: 'url value' }
  end

  def self.country_field(simple_form)
    # value = simple_form.object.kind_of?(CountryCondition) ? simple_form.object.value : nil
    value = nil

    simple_form.input_field :value, collection: ['USA', 'USA', 'USA'], value: value, disabled: true, class: 'country value'
  end

  def self.device_field(simple_form)
    # value = simple_form.object.kind_of?(DeviceCondition) ? simple_form.object.value : nil
    value = nil

    simple_form.input_field :value, collection: ['Desktop', 'Mobile'], value: value, disabled: true, class: 'device value'
  end
end
