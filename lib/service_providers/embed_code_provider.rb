class ServiceProviders::EmbedCodeProvider < ServiceProviders::Email
  class FirstAndLastNameRequired < StandardError; end

  URL_REGEX = /^(?:https?:\/\/|\/\/)/

  attr_reader :identity, :contact_list

  def initialize(opts = {})
    @identity = opts[:identity]
    @contact_list = opts[:contact_list]
  end

  def embed_code_valid?
    embed_code.present? && html.css('form').first.present?
  end

  def list_name
    html.css('h1').text
  end

  def list_id
    list_url.split('/').last
  end

  def embed_code
    contact_list.data['embed_code']
  end

  def embed_url
    html = Nokogiri::HTML embed_code
    reference_object = get_reference_object(html)
    url_for_form(reference_object)
  end

  def list_url
    if embed_code.match URL_REGEX
      embed_code
    else
      list_form.try(:attr, 'action') || embed_url
    end
  end

  def action_url
    html.css('form').first.try(:attr, 'action') || list_url
  end

  def list_form
    html.css('form').first
  end

  def required_params
    all_params.delete_if { |k, _| ([email_param] + name_params).include?(k) || k.nil? }
  end

  def all_params
    {}.tap do |hash|
      params.each do |input|
        name = input[:name]
        value = input[:value]
        hash[name] = value
      end
    end
  end

  def params
    list_form.css('input').collect do |input|
      { name: input.attr('name'), value: input.attr('value') }
    end
  end

  def email_param
    params.find { |i| i[:name].include? 'email' }[:name]
  end

  def name_param
    if name_params.length == 1
      name_params.first
    else
      raise FirstAndLastNameRequired
    end
  end

  def name_params
    params.collect do |i|
      i[:name] if i[:name].try :include?, 'name'
    end.compact || []
  end

  def subscribe_params(email, name, _double_optin = true)
    name ||= ''
    name_hash = {}

    if name_params.size >= 1
      first_name, last_name = name.split(' ')
      name_params.each do |name_field|
        name_hash[name_field] =
          case name_field
          when /first|fname/
            first_name || ''
          when /last|lname/
            last_name || ''
          else
            name
          end
      end
    end

    required_params.tap do |params|
      params[email_param] = email
      params.merge!(name_hash)
    end
  end

  private

  def html
    return @html if @html.present?

    html = Nokogiri::HTML embed_code

    reference_object = get_reference_object(html)
    url = url_for_form(reference_object)

    return @html = html if url.nil? || (!embed_code.match(URL_REGEX) && reference_object.nil?)

    remote_html = HTTParty.get(url) rescue ''

    # Pull from scripts and run
    if reference_object.try(:name) == 'script'
      match_data = extract_html_from_script(remote_html)
      if match_data.nil?
        raise 'Cannot parse remote html'
      else
        remote_html = match_data[1].gsub('\n', '').delete('\\')
      end
    end

    @html = Nokogiri::HTML(remote_html)
  end

  def extract_html_from_script(remote_html)
    remote_html.match(/^document.write\("(.+)"\)/)
  end

  def get_reference_object(html)
    html.css('body > iframe').first || html.css('head > script').first
  end

  # subclass to override reference
  def url_from_reference_object(reference_object)
    return nil unless reference_object
    case reference_object.name
    when 'script', 'iframe'
      reference_object.attr('src')
    when 'a'
      reference_object.attr('href')
    end
  end

  def url_for_form(reference_object)
    url = embed_code if embed_code.match URL_REGEX
    url ||= url_from_reference_object(reference_object) if reference_object

    return nil unless url

    url = 'http:' + url if url =~ /^\/\//
    url
  end
end
