class FillEmbedForm
  def initialize(form, email:, name: '', ignore: [], delete: [])
    @form = form.dup
    @params = @form.inputs
    @email = email
    @name = name
    @first_name, @last_name = name.to_s.split(' ', 2)
    @ignore_params = ignore
    @delete_params = delete
  end

  def call
    clean_params.tap do |result|
      result[email_param] = email
      name_params.each do |name_param|
        result[name_param] = value_for_name_part name_param
      end
    end
    @form
  end

  private

  attr_reader :params, :ignore_params, :email, :name, :first_name, :last_name

  def clean_params
    params.except!(*@delete_params)
  end

  def email_param
    params.keys.find { |param| param.include?('email') && ignore_params.exclude?(param) }
  end

  def name_params
    params.keys.select { |param| param.to_s.include?('name') && ignore_params.exclude?(param) }.compact
  end

  def value_for_name_part(field_name)
    case field_name
    when /first|fname/
      first_name || ''
    when /last|lname/
      last_name || ''
    else
      name
    end
  end
end
