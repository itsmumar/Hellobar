class ExtractEmbedForm
  URL_REGEX = /^(?:https?:\/\/|\/\/)/

  def initialize(embed_code)
    @embed_code = embed_code
  end

  # @return [EmbedForm]
  def call
    EmbedForm.new form, inputs, action_url
  end

  private

  attr_reader :html, :embed_code

  def form
    html.css('form').first
  end

  def inputs
    form&.css('input')&.inject({}) { |hash, input|
      hash.update input.attr('name').to_s => input.attr('value').to_s
    }.delete_if { |key, value|
      key.empty?
    }
  end

  def action_url
    form&.attr('action') || list_url
  end

  def list_url
    if embed_code.match URL_REGEX
      embed_code
    else
      embed_url
    end
  end

  def embed_url
    url =
      if embed_code.match URL_REGEX
        embed_code
      else
        url_from_reference_object
      end

    return unless url

    url =~ /^\/\// ? 'http:' + url : url
  end

  def html
    @_html ||= Nokogiri::HTML(remote_code? ? remote_code : embed_code)
  end

  def remote_code?
    embed_url.present?
  end

  def remote_code
    if reference_object&.name == 'script'
      match_data = extract_html_from_script(request_embed_url)
      raise 'Cannot parse remote html' if match_data.nil?
      match_data[1].gsub('\n', '').delete('\\')
    else
      request_embed_url
    end
  end

  def request_embed_url
    HTTParty.get(embed_url).to_s
  rescue => _
    ''
  end

  def extract_html_from_script(remote_html)
    remote_html.match(/^document.write\("(.+)"\)/)
  end

  def reference_object
    @reference_object ||=
      begin
        return embed_code_html.css('a').first if embed_code =~ /href=("|')https?:\/\/app.e2ma.net/
        embed_code_html.css('body > iframe').first || embed_code_html.css('head > script').first
      end
  end

  def url_from_reference_object
    return unless reference_object

    case reference_object.name
    when 'script', 'iframe'
      reference_object.attr('src')
    when 'a'
      reference_object.attr('href')
    end
  end

  def embed_code_html
    @embed_code_html ||= Nokogiri::HTML(@embed_code)
  end
end
