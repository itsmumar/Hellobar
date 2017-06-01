class FillEmbedForm
  def initialize(embed_html, email:, name: '')
    form = ExtractEmbedForm.new(embed_html).call
    @params = form.inputs.inject({}) { |hash, input| hash.update input[:name] => input[:value] }
    @email = email
    @name = name
    @first_name, @last_name = name.to_s.split(' ', 2)
  end

  def call
    params.dup.tap do |result|
      result[email_param] = email
      name_params.each do |name_param|
        result[name_param] = value_for_name_part name_param
      end
    end
  end

  private

  attr_reader :params, :email, :name, :first_name, :last_name

  def email_param
    params.keys.find { |param| param.include? 'email' }
  end

  def name_params
    params.keys.select { |param| param.include?('name') }.compact.presence || []
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
